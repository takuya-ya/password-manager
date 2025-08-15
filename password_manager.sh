#!/bin/bash

# ファイルを暗号化
encrypt_file()
{
    gpg --symmetric --yes --output user_inputs.gpg user_inputs.txt 2>> error.txt
    if [ $? -ne 0 ]; then
        echo 'ファイルの暗号化に失敗しました。'
        rm user_inputs.txt
        return 1
    fi
    rm user_inputs.txt
}

save_user_inputs()
{
    if [ -e user_inputs.gpg ]; then
        gpg -d --yes --output user_inputs.txt user_inputs.gpg 2>> error.txt
        if [ $? -ne 0 ]; then
            if tail -n 1 error.txt | grep -E 'Bad session key|No secret key' > /dev/null; then
                echo 'パスフレーズが間違っています。'
                gpgconf --reload gpg-agent
            else
                echo 'ファイルの復号化に失敗しました。'
            fi
            return 1
        fi
    fi

    (
        echo "$service_name:$user_name:$password:$email" >> user_inputs.txt
    ) 2>> error.txt

    if [ $? -ne 0 ]; then
        echo '入力内容の保存に失敗しました。'
        rm user_inputs.txt
        return 1
    fi
}

# 個別フィールドのバリデーション関数
validate_field()
{
    # 引数をローカル変数に代入
    local field_value="$1"
    local field_display_name="$2"
    local max_chars="$3"

    if [ -z "$field_value" ]; then
        error_messages+=("${field_display_name}が入力されていません。")
    elif [ "${#field_value}" -gt "$max_chars" ]; then
        error_messages+=("${field_display_name}は${max_chars}文字以内で入力してください。")
    fi
}

# メールアドレス専用のバリデーション関数
validate_email_field()
{
    local email="$1"
    local max_chars="$2"
    
    if [ -z "$email" ]; then
        error_messages+=("メールアドレスが入力されていません。")
    elif [ "${#email}" -gt "$max_chars" ]; then
        error_messages+=("メールアドレスは${max_chars}文字以内で入力してください。")
    elif [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error_messages+=("正しいメールアドレス形式で入力してください。")
    fi
}

# 全フィールドのバリデーション
validation_user_inputs()
{
    local MAX_CHARACTERS=50

    validate_field "$service_name" "サービス名" "$MAX_CHARACTERS"
    validate_field "$user_name" "ユーザー名" "$MAX_CHARACTERS"
    validate_field "$password" "パスワード" "$MAX_CHARACTERS"
    validate_email_field "$email" "100"  # メールアドレスは100文字まで
}

add_password()
{
    # 通常の変数でユーザー入力を管理
    local service_name=""
    local user_name=""
    local password=""
    local email=""
    local error_messages=()

    read -p 'サービス名を入力して下さい：' service_name
    read -p 'ユーザー名を入力して下さい：' user_name
    # -sオプションで入力内容を非表示化
    read -s -p 'パスワードを入力して下さい：' password
    echo ''
    read -p 'メールアドレスを入力して下さい：' email

    validation_user_inputs
    if [ ${#error_messages[@]} -eq 0 ]; then
        # 入力が正常な場合、入力を保存
        save_user_inputs || return
    else
        # 入力に異常がある場合、配列のエラー文を出力
        for error in "${error_messages[@]}"; do
            echo  $error
        done
        return
    fi

    # ファイルを暗号化。失敗した場合、メニュー選択に戻る
    encrypt_file || return
    echo 'パスワードの追加は成功しました。'
}

get_password()
{
    # ユーザー入力を確認
    # -p オプションは read コマンドでプロンプトを表示するために使います
    read -p 'サービス名を入力してください：' search_name
    if [ -z "$search_name" ]; then
        echo -e "\nサービス名が入力されていません。"
        return
    fi

    # 入力されたサービス名のデータを確認
    local decrypt_error search_error output_error
    # 複合化、サービス名の検索、仕様に則した出力
    gpg -d --yes user_inputs.gpg 2>> error.txt |
        grep "^$search_name" 2>> error.txt |
        awk -F ':' '$1 !="" {print "サービス名:"$1 "\nユーザー名:"$2 "\nパスワード:"$3 "\nメールアドレス:"$4"\n"}' 2>> error.txt

    # 直前のパイプラインにおける各コマンドの終了ステータスを格納
    decrypt_error="${PIPESTATUS[0]}"
    search_error="${PIPESTATUS[1]}"
    output_error="${PIPESTATUS[2]}"

    if [ "$decrypt_error" -ne 0 ]; then
        if tail -n 1 error.txt | grep -E 'Bad session key|No secret key' > /dev/null; then
            echo -e 'パスフレーズが間違っています。\n'
            gpgconf --reload gpg-agent
        else
            echo -e 'ファイルの復号化に失敗しました。\n'
        fi
    elif [ "$search_error" -ne 0 ]; then
        echo -e 'そのサービスは登録されていません。\n'
    # TODO:awkのエラーハンドリング
    fi
}

echo 'パスワードマネージャーへようこそ！'
while true; do
    read -p '次の選択肢から入力してください(Add Password/Get Password/Exit):' menu
    echo ''
    case $menu in
        'Add Password')
            add_password
            ;;
        'Get Password')
            get_password
            ;;
        # exitを遅延させて感謝メッセージの視認性を向上
        'Exit')
            echo -e "Thank you\033[31m!\033[0m"
            sleep 1.5
            exit
            ;;
        *)
            echo ''
            echo  '入力が間違えています。Add Password/Get Password/Exit から入力してください。'
            ;;
    esac
done
