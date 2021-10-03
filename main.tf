locals {
  lambda_role_name       = "${terraform.workspace}-${var.suffix}-role_lambda"
  cloudwatch_policy_name = "${terraform.workspace}-${var.suffix}-policy_cloudwatch"
  lambda_function_name   = "${var.suffix}-${terraform.workspace}-lambda"
  tag                    = "${terraform.workspace}"
  rest_api_name          = "${var.suffix}-${terraform.workspace}-API"
}


data "archive_file" "code_zip" {
  type        = "zip"
  output_path = "/tmp/function.zip"
  source_file = "files/main.py"
}
resource "aws_lambda_function" "task16_lambda" {
  filename         = data.archive_file.code_zip.output_path
  function_name    = local.lambda_function_name
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.code_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  tags = {
    Environment = local.tag
  }
  environment {
    variables = {
      my_name = "chizzy"
    }
  }
}

resource "aws_api_gateway_rest_api" "MyAPI" {
  name        = local.rest_api_name
  description = "Api to trigger lambda from terraform"
}

resource "aws_api_gateway_resource" "MyResource" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  parent_id   = aws_api_gateway_rest_api.MyAPI.root_resource_id
  count       = length(var.path_names)
  path_part   = var.path_names[count.index]
}

resource "aws_api_gateway_method" "PostMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyAPI.id
  resource_id   = aws_api_gateway_resource.MyResource[0].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "GetMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyAPI.id
  resource_id   = aws_api_gateway_resource.MyResource[1].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.MyAPI.id
  resource_id             = aws_api_gateway_resource.MyResource[1].id
  http_method             = aws_api_gateway_method.GetMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.task16_lambda.invoke_arn
  depends_on = [
    aws_api_gateway_method.GetMethod
  ]
}

resource "aws_api_gateway_integration" "integration_2" {
  rest_api_id             = aws_api_gateway_rest_api.MyAPI.id
  resource_id             = aws_api_gateway_resource.MyResource[0].id
  http_method             = aws_api_gateway_method.PostMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.task16_lambda.invoke_arn
}


resource "aws_api_gateway_deployment" "test" {
  depends_on = [
    aws_api_gateway_integration.integration,
  ]

  rest_api_id = "${aws_api_gateway_rest_api.MyAPI.id}"
  stage_name  = "test"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.test.invoke_url}"
}
