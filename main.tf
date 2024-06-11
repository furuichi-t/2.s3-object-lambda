resource "aws_s3_bucket" "tf-s3" { 
  bucket = "object-s3-lambda-furuichi"
  force_destroy = true 
}

resource "aws_s3_object" "tf-object" { 
  bucket = aws_s3_bucket.tf-s3.bucket 
  key = "2.3 aws logo.f00a88b928cdc48ba417e90c2c1eab9d961899d1.png" 
  source = "/home/furuichi-ubuntu/S3-object-lambda/2.3 aws logo.f00a88b928cdc48ba417e90c2c1eab9d961899d1.png"
  content_type = "image/png" 
}

resource "aws_s3_access_point" "tf-ap" {
  name = "s3-object-lambda"
  bucket = aws_s3_bucket.tf-s3.id 
}

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

resource "aws_iam_role_policy_attachment" "tf-policy-attach" { 
  role       = aws_iam_role.ol_lambda_images.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}



data "archive_file" "tf-lambda-code" { 
  type = "zip"
  source_dir  = "/home/furuichi-ubuntu/S3-object-lambda/lambda"
  output_path = "/home/furuichi-ubuntu/S3-object-lambda/lambda/terraform_lambda.zip"
}

resource "aws_lambda_function" "tf-lambda" { 
  function_name = "ol_image_processing" 
  filename         = data.archive_file.tf-lambda-code.output_path
  source_code_hash = data.archive_file.tf-lambda-code.output_base64sha256
  role = aws_iam_role.ol_lambda_images.arn
  runtime = "python3.9" 
  handler = "terraform_lambda.handler" 
  memory_size = "1024" 
    layers = [
        "arn:aws:lambda:ap-northeast-1:770693421928:layer:Klayers-p39-pillow:1"
    ]
} 


resource "aws_s3control_object_lambda_access_point" "tf-s3-object-lambda" {
  name = "ol-amazon-s3-images-guide"

  configuration {
   supporting_access_point = aws_s3_access_point.tf-ap.arn 

    transformation_configuration { 
      actions = ["GetObject"]

      content_transformation { 
        aws_lambda {
          function_arn = aws_lambda_function.tf-lambda.arn 
        }
      }
    }
  }
}
