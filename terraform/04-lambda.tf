
data "aws_iam_role" "cruddurPostConfirmationRole" {
    name = "cruddur-post-confirmation-role-zmecbzal"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
    role       = data.aws_iam_role.cruddurPostConfirmationRole.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}