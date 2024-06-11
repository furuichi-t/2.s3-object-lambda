resource "aws_s3_bucket" "tf-s3" { #S3バケット作成
  bucket = "object-s3-lambda-furuichi"
  force_destroy = true #S3バケット削除の時に中にオブジェクトがあっても強制削除しますよというオプション
}

resource "aws_s3_object" "tf-object" { #バケットにオブジェクトアップロード
  bucket = aws_s3_bucket.tf-s3.bucket #key値がバケット内の階層を指す　今回は一番上の改装に.pngをアップロードしたかったので直接ファイル名を打ち込んだ　
  key = "2.3 aws logo.f00a88b928cdc48ba417e90c2c1eab9d961899d1.png" #sourceがアップロードするローカルのファイル　keyが指定した階層にファイルをアップロードする
  source = "/home/furuichi-ubuntu/S3-object-lambda/2.3 aws logo.f00a88b928cdc48ba417e90c2c1eab9d961899d1.png"
  content_type = "image/png" #content_typeは他にもtext/htmlなどあるからアップロードしたいファイルによって変更しよう
}

resource "aws_s3_access_point" "tf-ap" {
  name = "s3-object-lambda"
  bucket = aws_s3_bucket.tf-s3.id 
  #ネットワークオリジンにinternetとvpcがありinternetを選択することは出来なかったがvpc_configurationを設定しなかった場合network_origin : Internetとアウトプットされた！！
}

#lambdaを作成する前に先にIAMロールを作る　lambdaにアタッチするので必要になる
resource "aws_iam_role" "ol_lambda_images" {
  name = "ol-lambda-images2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tf-policy-attach" { #IAMロールにポリシーをアタッチ
  role       = aws_iam_role.ol_lambda_images.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}



data "archive_file" "tf-lambda-code" { #ローカルのlambdaﾌｧｲﾙをzip化しlambda-functionに読み込ませる準備
  type = "zip"
  source_dir  = "/home/furuichi-ubuntu/S3-object-lambda/lambda"
  output_path = "/home/furuichi-ubuntu/S3-object-lambda/lambda/terraform_lambda.zip"
}

resource "aws_lambda_function" "tf-lambda" { #lambda関数を作成
  function_name = "ol_image_processing" #lambda関数の名前
  filename         = data.archive_file.tf-lambda-code.output_path
  source_code_hash = data.archive_file.tf-lambda-code.output_base64sha256
  role = aws_iam_role.ol_lambda_images.arn #作成したロールをlambdaにアタッチ
  runtime = "python3.9" #今回はハンズオンに従ってpythonを指定
  handler = "terraform_lambda.handler" #(lambdaファイル名).handler
  memory_size = "1024" #メモリーのサイズ デフォルト256やった気がする
    layers = [
        "arn:aws:lambda:ap-northeast-1:770693421928:layer:Klayers-p39-pillow:1"
    ]
} 


resource "aws_s3control_object_lambda_access_point" "tf-s3-object-lambda" {
  name = "ol-amazon-s3-images-guide"

  configuration {
   supporting_access_point = aws_s3_access_point.tf-ap.arn #アクセスポイントの指定

    transformation_configuration { #行う動作を指定
      actions = ["GetObject"]

      content_transformation { 
        aws_lambda {
          function_arn = aws_lambda_function.tf-lambda.arn #lambdaを指定
        }
      }
    }
  }
}

#ほぼほぼの側は出来たがcloudshellで実行する部分が分からない、、、　そもそもcloudshellの部分で何しているかを把握すればterraformに落とし込めるかもしれないが
#linuxの知識がないせいか何をしているかが分からない上にそれをawsに落とし込むのもawsへの知識が不足しているせいでわからない
#cloudshellで実行する部分のコマンドが何をしようとしているか一つずつ調べる　その前に③のcloudformationをterraformに変換する