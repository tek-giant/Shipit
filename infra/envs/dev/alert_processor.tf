data "archive_file" "alert_processor" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/alert_processor"
  output_path = "${path.module}/.build/alert_processor.zip"
  excludes    = ["test_handler.py", "__pycache__"]
}

resource "aws_cloudwatch_log_group" "alert_processor" {
  name              = "/aws/lambda/shipit-dev-alert-processor"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alert_processor" {
  name               = "shipit-dev-alert-processor"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Only permission: write to its own log group
data "aws_iam_policy_document" "alert_processor_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.alert_processor.arn}:*"]
  }
}

resource "aws_iam_role_policy" "alert_processor_logs" {
  name   = "write-own-logs"
  role   = aws_iam_role.alert_processor.id
  policy = data.aws_iam_policy_document.alert_processor_logs.json
}

resource "aws_lambda_function" "alert_processor" {
  function_name    = "shipit-dev-alert-processor"
  role             = aws_iam_role.alert_processor.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.alert_processor.output_path
  source_code_hash = data.archive_file.alert_processor.output_base64sha256
  timeout          = 10
  memory_size      = 128

  depends_on = [
    aws_cloudwatch_log_group.alert_processor,
    aws_iam_role_policy.alert_processor_logs,
  ]
}

resource "aws_lambda_permission" "from_sns" {
  statement_id  = "AllowSnsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "alert_processor" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_processor.arn

  depends_on = [aws_lambda_permission.from_sns]
}
