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

Please note that this was only a test user!  I created and used an additional user using the sign up, sign in Auth flows developed in this weeks camp!
 
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
```

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

## BackeEnd Auth work

This section was a lot more challenging, but I learnt a lot.  I really enjoyed getting my head around the python in both the Cruddur parts of the code as well as the library we installed/setup for the use of `Flask-AWSamplify`.

My first task was to endure that the authentication header was visible.  The lines are now commented, but I played with both sending the token to rollbar (not something I would do in practice for security reasons) and logging it locally:

```diff
@app.route("/api/activities/home", methods=['GET'])
def data_home():
+  #rollbar.report_message(request.headers.get('Authorization'), 'info')
+  #app.logger.debug(request.headers.get('Authorization'))
  data = HomeActivities.run()
  return data, 200
```

In both cases, I was able to see the Bearer token so I was quite please.  Of course, I needed to ensure the header was pushed through from `App.py` on the call to home, as shown here:

```javascript
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("access_token")}`
        },
        method: "GET"
      });
 ```
 
 One other change worthy of note is the addition of the variables required in the backend-flask section of the dockerfile:
 
 ```dockerfile
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
      AWS_COGNITO_USER_POOL_ID: "${REACT_APP_AWS_USER_POOLS_ID}"
      AWS_COGNITO_USER_POOL_CLIENT_ID: "${REACT_APP_CLIENT_ID}"
    build: ./backend-flask
  
```

I also forgot the CORS changes, which had me scratching my head.  I didn't follow the live stream, instead I watched it through and then had to return on occasions when completing the tasks.  Anyway, finally I used the browser devtools inspector and it was obvious there was a CORS error, I fixed this:

```python
...

 cors = CORS(
  app, 
  resources={r"/api/*": {"origins": origins}},
  expose_headers="location,link",
  allow_headers="content-type,if-modified-since",
  headers=['Content-Type', 'Authorization'], 
  expose_headers='Authorization',
  methods="OPTIONS,GET,HEAD,POST"
)

...
```

### The cognito JWT library

I won't paste the entire file here, but I then added the `cognito_jwt_token.py` file.

[cognito_jwt_token.py](/backend-flask/lib/cognito_jwt_token.py)

### Integrating the JWT library

Firstly, it needs importing, the full class plus a method and the custom exception `TokenVerifyError`;

```python
from lib.cognito_jwt_token import CognitoJwtToken, extract_access_token, TokenVerifyError
```

We use the class to get the token on line 60:

```python
cognito_jwt_token = CognitoJwtToken(
  user_pool_id=os.getenv("AWS_COGNITO_USER_POOL_ID"), 
  user_pool_client_id=os.getenv("AWS_COGNITO_USER_POOL_CLIENT_ID"),
  region=os.getenv("AWS_DEFAULT_REGION")
)
```

The token is extracted using `extract_access_token` which simply uses the request headers to grab the `Authorisation` header and then split it into an array and assign/return the actual JWT token value.  This is on line 160:

```python
access_token = extract_access_token(request.headers)
```

Next, we need to branch on the call to `HomeActivities.run()`.  One option without any params as before (but only if we failed to get the token) and a new option that calls it and passes the claim for the username returned from a call to `cognito_jwt_token_verify(access_token)`:

```python
...

  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    app.logger.debug(claims['username'])
    data = HomeActivities.run(cognito_user_id=claims['username'])
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    app.logger.debug("unauthenicated")
    data = HomeActivities.run()
  return data, 200
  
...
```

I followed the example and simply inserted a new Crud at position 0 inside home_activities.py if the user is logged in (cognito_user_id is not null (None in Python)).

```python
...


      
      if cognito_user_id != None:
        extra_crud = {
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Lore',
          'message': 'My dear brother, it the humans that are the problem',
          'created_at': (now - timedelta(hours=1)).isoformat(),
          'expires_at': (now + timedelta(hours=12)).isoformat(),
          'likes': 1042,
          'replies': []
        }
        results.insert(0,extra_crud)

...
```

Finally, we have success the authentication flow works in my app!.


