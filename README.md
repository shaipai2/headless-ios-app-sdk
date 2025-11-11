# Pre-Requisites
- Xcode 

# Steps to start the application

## 1. Download the source

## 2. Log in to CCaaS intance portal 
- Make a note of **"Company Secret"** and **"Company Key"** from Developer settings

## 3. Make the following changes to the local server configuration
- The local server will generate the JWT token which will be used to authenticate and connect to the CCaaS intance
- In the downloaded source directory, cd into the server folder
- **In .env file** 
  - update the value of the **"COMPANY_SECRET"** with the value of "Company Secret Code" noted in **"Step 2"** above
  - update the value of the **"PORT"** with the value of "3000" or any other port value

## 4. Start the local server
- From the server folder run the server using the ***node app.js*** command from the terminal 
- Make a note of the URL where the server is listening to the requests
   
## 5. Make the following changes in the App code 
- **In Common/Resources/environment.json file**
  - update the value of the **"key"** with the value of "Company Key" from CCaaS 
  - update the value of **"hostname"** with the value of the CCaaS intance host name
-  **In CCaaS_App/CCaaSMessageManager.swift file**
   -  Update the value of **"secretKey"** in ***FormCompletePayloadGenerator()*** function. The secretkey value can be found in the *CCaas->Settings->Forms->Forms Settings*
   -  Update the value of **"serverURL"** in ***getFormSubmitSignature()*** function. This is the url to your own service which will respond back with a payload and signature.  
-  **In CCaaS_App/Components/ChatDelegate.swift file** 
   -  The class has a function which will get the external Form url which the App will use to display the Form
   -  Update the value of **"serverURL"** in ***handleWebFormRequest()*** function. This is the url to your own Forms service which will respond back with Form payload (html payload).
-  **In Common/Controller/Authcontroller.swift file**
   -  Update the value of the **"signingBaseUrl"** variable with the server url 
-  **In CCaaS_App/CCaaSChatView.swift file** 
   -  update the **"meuId"** parameter when calling the *messagesManager.startChat*. This id shoud be the id of the queue which is configured in CCaaS


## 6. Run the App
- From the Xcode run the app which will open the SwiftUI simulator and open the app.  