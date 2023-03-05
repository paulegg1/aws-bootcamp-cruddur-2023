# Week 3 — Decentralized Authentication

## Provision Cognito

For this, due to my aversion to clickOps, I attempted (with success) to deploy the Cognito user pool and client using Terraform.  The TF HCL could definitely be improved, but for now - it works!

```terraform
resource "aws_cognito_user_pool" "user_pool" {
  name = "cruddur-pool"

  username_configuration {
    case_sensitive = false
  }
  alias_attributes = ["email"]
  auto_verified_attributes = ["email"] 
  password_policy {
    minimum_length = 8
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

    schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "preferred_username"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "cruddur-client"

  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false
  refresh_token_validity = 90
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  
}
```

Note the importance of not forgetting to include STP_AUTH ! :

```terraform
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
 ```
 
 ### Installing AWS Amplify
 
 This was straigtfoward:
 
 ```sh
 npm i aws-amplify --save
 ```
 
 ### Configure Amplify
 
 
