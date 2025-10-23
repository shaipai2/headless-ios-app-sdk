# Pre-Requisites
- Xcode 

# Steps to start the application

## 1. Download the source

## 2. Make the following changes in the App code 
- **In Common/Resources/environment.json file**
  - update the value of the **"key"** with the value of "Company Key" from CCaaS 
  - update the value of **"hostname"** with the value of the CCaaS intance host name
-  **In CCaaSMessageManager.swift file**
   -  Update the value of **"secretKey"** in ***FormCompletePayloadGenerator()*** function. The secretkey value can be found in the *CCaas->Settings->Forms->Forms Settings*
   -  Update the value of **"serverURL"** in ***getFormSubmitSignature()*** function. This is the url to your own service which will respond back with the signature.  
-  **In ChatDelegate.swift file** 
   -  The class has a function which will get the external Form url which the App will use to display the Form
   -  Update the value of **"serverURL"** in ***handleWebFormRequest()*** function. This is the url to your own Forms service which will respond back with Form url.

## 3. Make the following changes to the local server configuration
- The local server will generate the JWT token which will be used to authenticate and connect to the CCaaS intance
- cd into the server folder
- **In .env file** 
  - update the value of the **"COMPANY_SECRET"** with the value of "Company Secret Code" from CCaaS
  - update the value of the **"PORT"** with the value of "3000" from CCaaS

## 4. Start the local server
- Run the server using the ***node app.js*** command from the terminal

## 5. Run the App 