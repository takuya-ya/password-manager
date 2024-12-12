#!/bin/bash

# 未入力項目と文字数超過を確認し、該当するエラーメッセージを配列に追加
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
        elif [ "${#user_inputs[$indent]}" -ge "$MAX_CAHRACTERS" ]; then
            error_messages+=("${length_errors[$indent]}")
        fi
    done
}

save_user_inputs()
{
    (
        echo "${user_inputs['service_name']}":"${user_inputs['user_name']}":"${user_inputs['password']}" >> user_inputs
    ) 2>> error.txt

    if [ $? -ne 0 ]; then
        echo   '入力内容の保存に失敗しました。'
        return
    fi

    echo 'パスワードの追加は成功しました。'
}

add_password()
{
    local -A user_inputs=(['service_name']='' ['user_name']='' ['password']='')
    local -a error_messages=()

    read -p 'サービス名を入力して下さい：' user_inputs['service_name']
    read -p 'ユーザー名を入力して下さい：' user_inputs['user_name']
    read -p 'パスワードを入力して下さい：' user_inputs['password']
    echo ''

    validation_user_inputs

    if [ -z "$error_messages" ]; then
        # 入力が正常な場合、入力を保存
        save_user_inputs
    else
        # 入力に異常がある場合、配列のエラー文を出力
        for error in "${error_messages[@]}"; do
            echo  $error
        done
    fi
}

get_password()
{
    read -p 'サービス名を入力してください:' search_name
        if [ -z "$search_name" ]; then
            echo -e "\nサービス名が入力されていません。"
            return
        fi

    matched_data=$(grep "^$search_name" user_inputs)
    if [ $? -eq 0 ]; then
        echo "$matched_data" | awk -F ':' '{print "\nサービス名:"$1 "\nユーザー名:"$2 "\nパスワード:"$3}'
    else
        echo -e '\nそのサービス名は登録されていません。'
    fi
}

echo 'パスワードマネージャーへようこそ！'
while true; do
    read -p '次の選択肢から入力してください(Add Password/Get Password/Exit):' menu
    case $menu in
    # TODO: 手動テスト簡略化の為、一時的にパターンを省略
        'a')
            add_password
            ;;
        'g')
            get_password
            ;;
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
