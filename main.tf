# Terraform provider configuration for AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS provider configuration
provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_sns_topic" "my_sns_topic" {
  name = "MySNSTopic"  # Provide a name for your SNS topic
}


resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.my_sns_topic.arn
  protocol  = "email"
  endpoint  = "random-aaaaj36uvru2jxbsurtdn5isni@quecloudsolutions.slack.com"  # Replace with your email address
}


# AWS Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  filename      = "lambda_function.zip" # Your Lambda function deployment package
  function_name = "StopEC2AndSendReport"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300 # Set the timeout to 5 minutes (300 seconds)

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.my_sns_topic.arn  # Use the SNS topic ARN you created
    }
  }
}






# Create a CloudWatch Events rule for executing the Lambda function every 3 minutes
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name        = "Every3MinutesLambdaExecution"
  description = "Execution of Lambda every 3 minutes"
  schedule_expression = "rate(3 minutes)"
}




# Attach the Lambda function as a target for the CloudWatch Events rule
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.my_lambda_function.arn
}





# Add an IAM role for your Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach the Lambda execution policy
resource "aws_iam_policy_attachment" "lambda_permissions" {
  name        = "lambda-attachment"
  policy_arn = aws_iam_policy.lambda_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}

# Define the Lambda execution policy
resource "aws_iam_policy" "lambda_policy" {
  name = "LambdaExecutionPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "*",
        Resource = "*"
      }
    ]
  })
}
