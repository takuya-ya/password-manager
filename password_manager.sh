#!/bin/bash

# ファイルを暗号化
encrypt_remove_file()
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
        echo "${user_inputs['service_name']}":"${user_inputs['user_name']}":"${user_inputs['password']}" >> user_inputs.txt
    ) 2>> error.txt

    if [ $? -ne 0 ]; then
        echo '入力内容の保存に失敗しました。'
        rm user_inputs.txt
        return 1
    fi
}

validation_user_inputs()
{
    local -A input_errors=(
        ['service_name']='サービス名が入力されていません。'
        ['user_name']='ユーザー名が入力されていません。'
        ['password']='パスワードが入力されていません。'
    )
    local -A length_errors=(
        ['service_name']='サービス名は50文字以内で入力してください。'
        ['user_name']='ユーザー名は50文字以内で入力してください。'
        ['password']='パスワードは50文字以内で入力してください。'
    )
    MAX_CAHRACTERS=50

    # user_inputsのインデントをindentとしてループし、ユーザー入力情報とエラー文を紐づける
    for indent in "${!user_inputs[@]}"; do
        if [ -z "${user_inputs[$indent]}" ]; then
            error_messages+=("${input_errors[$indent]}")
        elif [ "${#user_inputs[$indent]}" -gt "$MAX_CAHRACTERS" ]; then
            error_messages+=("${length_errors[$indent]}")
        fi
    done
}

add_password()
{
    # 配列のスコープを関数内に限定し、アクセスを制限
    local -A user_inputs=(['service_name']='' ['user_name']='' ['password']='')
    local -a error_messages=()

    read -p 'サービス名を入力して下さい：' user_inputs['service_name']
    read -p 'ユーザー名を入力して下さい：' user_inputs['user_name']
    # -sオプションで入力内容を非表示化
    read -s -p 'パスワードを入力して下さい：' user_inputs['password']
    echo ''

    validation_user_inputs
    if [ -z "$error_messages" ]; then
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
    encrypt_remove_file || return
    echo 'パスワードの追加は成功しました。'
}

get_password()
{
    # ユーザー入力を確認
    read -p 'サービス名を入力してください:' search_name
        if [ -z "$search_name" ]; then
            echo -e "\nサービス名が入力されていません。"
            return
        fi

    # 入力されたサービス名のデータを確認
    local -A result
    # 複合化、サービス名の検索、仕様に則した出力
    gpg -d --yes user_inputs.gpg 2>> error.txt |
        grep "^$search_name" 2>> error.txt |
        awk -F ':' '$1 !="" {print "サービス名:"$1 "\nユーザー名:"$2 "\nパスワード:"$3"\n"}' 2>> error.txt

    # 直前のパイプラインにおける各コマンドの終了ステータスを格納
    result=(
            ['decrypt_error']="${PIPESTATUS[0]}"
            ['search_error']="${PIPESTATUS[1]}"
            ['output_error']="${PIPESTATUS[2]}"
    )

    if [ "${result['decrypt_error']}" -ne 0 ]; then
        if tail -n 1 error.txt | grep -E 'Bad session key|No secret key' > /dev/null; then
            echo -e 'パスフレーズが間違っています。\n'
            gpgconf --reload gpg-agent
        else
            echo -e 'ファイルの復号化に失敗しました。\n'
        fi
    elif [ "${result['search_error']}" -ne 0 ]; then
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
