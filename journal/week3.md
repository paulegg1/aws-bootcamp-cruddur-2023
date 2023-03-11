# Week 3 — Decentralized Authentication

## Provision Cognito

For this, due to my aversion to clickOps, I attempted (with success) to deploy the Cognito user pool and client using Terraform.  The TF HCL could definitely be improved, but for now - it works!

```terraform
resource "aws_cognito_user_pool" "user_pool" {
  name = "cruddur-pool"

  username_configuration {
    case_sensitive = false
  }
  username_attributes        = ["email"]
  # The line above conflicts with this one, they are mutually exclusive
  #alias_attributes = ["email"]
  auto_verified_attributes = ["email"] 
  password_policy {
    minimum_length = 8
    temporary_password_validity_days = 7
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
 
 I also faked a user creation in order to test things out and have an early confirmed user:
 
```terraform
resource "aws_cognito_user" "paulegg" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = "pauleggleton"
  desired_delivery_mediums = ["EMAIL"]
  password = "Testing123!"

  attributes = {
    email          = "paulegg@gmail.com"
    email_verified = true
    name           = "Paul Eggleton"
    preferred_username = "pauleggleton"

  }
}
```
 
 ## Installing AWS Amplify
 
 This was straigtfoward:
 
 ```sh
 npm i aws-amplify --save
 ```

It is worth noting that the `--save` option populates `~/frontend-react-js/package.json`:

```diff
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0",
+   "aws-amplify": "^5.0.16",
    "js-cookie": "^3.0.1",
    "luxon": "^3.1.0",
```
 
### Configure Amplify

There are a few steps here that I did to configure AWS Amplify and connect up the application. Firstly, there are some environment variables that need configuring and passing via process.env.VAR syntax into the application.  The environment variables start with the `docker-compose.yml` :
 
```dockerfile
...
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_USER_POOLS_ID: "${REACT_APP_AWS_USER_POOLS_ID}"
      REACT_APP_CLIENT_ID: "${REACT_APP_CLIENT_ID}"
    build: ./frontend-react-js
...
 
The changes to `App.js` were as follows:

```javascript

import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});

```

## FrontEnd JS work

### Conditional display of components 

#### homeFeedPage.js

Next, I changed the `~/frontend-react.js/src/pages/homefeedpage.js` to put conditionals around the display (or not) of the components depending on the logged-in state:

Addition of line to import `Auth` on line 11:

```javascript
import { Auth } from 'aws-amplify';
```

Lines around 43+ replacement of the checkAuth function expression:

```javascript
...
// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};
...
```

#### profileInfo.js

I edited the `~/frontend-react.js/src/components/profileInfo.js` page to replace the contents of `const signOut` and to include an import of Auth.  This implements a sign out call for us that uses Auth to call back to Cognito.

```javascript

...

import { Auth } from 'aws-amplify';

...


  const signOut = async () => {
    try {
        // Auth sign out global - all locations
        await Auth.signOut({ global: true });
        window.location.href = "/"
    } catch (error) {
        console.log('error signing out: ', error);
    }
  }
  
...

```


#### signInPage.js


I edited the `~/frontend-react.js/src/pages/signInPage.js` page to replace `const onsubmit` and to include an import of Auth.  This implements a sign in call by leveraging `Auth.signin()` using the users email and password.

```javascript

...

import { Auth } from 'aws-amplify';

...

  const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
      Auth.signIn(email, password)
        .then(user => {
          localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
          window.location.href = "/"
        })
        .catch(error => {  
          if (error.code == 'UserNotConfirmedException') {
            window.location.href = "/confirm"
          }
          setErrors(error.message)
        });       
    return false
  }



...
```

### Sign Up

#### SignupPage.js

I imported th e Auth module from `aws-amplify` 

```diff
- // [TODO] Authenication
- import Cookies from 'js-cookie'
+ //  Authenication
+ import { Auth } from 'aws-amplify';
```

Next, I needed to change the onsubmit so that it no longer faked things with cookies but instead used the `Auth.signUp` call, supplying the form provided username, password and attributes:

```javascript
const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
  } catch (error) {
      console.log(error);
      setErrors(error.message)
  }
  return false
}
```

### Code confirmation

#### ConfirmationPage.js

Again, the necessary import of `Auth`

```diff
- import Cookies from 'js-cookie'
+ import { Auth } from 'aws-amplify';
```

Next I did the rewrite of `resend_code` and `onsubmit`

```javascript
const resend_code = async (event) => {
  setErrors('')
  try {
    await Auth.resendSignUp(email);
    console.log('code resent successfully');
    setCodeSent(true)
  } catch (err) {
    // does not return a code
    // does cognito always return english
    // for this to be an okay match?
    console.log(err)
    if (err.message == 'Username cannot be empty'){
      setErrors("You need to provide an email in order to send Resend Activiation Code")   
    } else if (err.message == "Username/client id combination not found."){
      setErrors("Email is invalid or cannot be found.")   
    }
  }
}
```

```javascript
const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
    await Auth.confirmSignUp(email, code);
    window.location.href = "/"
  } catch (error) {
    setErrors(error.message)
  }
  return false
}
```

I had an issue on the `signupPage.js`; I kept getting the message `incorrect confirmation code`.  It turned out to be a mix with email/username, here's the fix in `onsubmit`, line 23:

```diff
      const { user } = await Auth.signUp({
-        username: email,
+        username: username,
```

Once that was in place, the signup worked!

### Recovery of account

#### RecoverPage.js

The usual import was added, then I replaced both `onsubmit_send_code` and `onsubmit_confirm_code`; they need to call Auth.forgotPassword(username)` and `Auth.forgotPasswordSubmit(username, code, password)` respectively.

```javascript
const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setErrors(err.message) );
  return false
}

const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setErrors(err.message) );
  } else {
    setErrors('Passwords do not match')
  }
  return false
}
```


