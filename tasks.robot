*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Dialogs
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault


*** Variables ***
${ORDERS_CSV_URL}=   https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Open the robot order website
    
    ${secret}=    Get Secret  secret
    Open Available Browser  ${secret}[url]
*** Keywords ***
Get orders
     ${response}=    Download   ${ORDERS_CSV_URL}  target_file=${TEMPDIR}${/}tiedosto.csv  overwrite=true
     ${table}=    Read table from CSV  ${TEMPDIR}${/}tiedosto.csv
     [Return]  ${table}

Close the annoying modal
     Click Button When Visible  //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Preview the robot
    Click Button    //*[@id="preview"]

Submit the order
     Click Button    //*[@id="order"]
     Assert order succeeded

Assert order succeeded
     Element Should Be Visible    id:receipt 

Store the receipt as a PDF file
      [Arguments]  ${OrderNumber}
       ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
      Html To Pdf    ${receipt_html}    ${TEMPDIR}${/}${OrderNumber}.pdf
      [Return]  ${TEMPDIR}${/}${OrderNumber}.pdf

Take a screenshot of the robot
     [Arguments]  ${OrderNumber}
     Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[1]
     Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[2]
     Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[3]

     Capture Element Screenshot   //*[@id="robot-preview-image"]    ${TEMPDIR}${/}${OrderNumber}.png
     [Return]  ${TEMPDIR}${/}${OrderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}   ${pdf}
      ${files}=    Create List   ${pdf}   ${screenshot}
    Add Files To Pdf   ${files}   ${pdf}
Go to order another robot
   Click Button    //*[@id="order-another"]


Create a ZIP file of the receipts
    [Arguments]  ${zipFileName}
   
    Archive Folder With Zip   ${TEMPDIR}      ${OUTPUT_DIR}${/}${zipFileName}   include=*.pdf

Fill the form
    [Arguments]  ${row}
    Select From List By Index    //*[@id="head"]   ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text     //*[@placeholder="Enter the part number for the legs"]    text=${row}[Legs]
    Input Text     //*[@id="address"]    text=${row}[Address]

Ask the zip file name
    Add heading       Give ZIP file name
    Add text input    ZipFileName    label=ZIP file name
     
    ${result}=    Run dialog
    [Return]  ${result.ZipFileName} 


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${zipFileName}=  Ask the zip file name
   
    Open the robot order website
    ${orders}=    Get orders
    
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form  ${row}
        Preview the robot
        Wait Until Keyword Succeeds  5x   1s  Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=  Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    
    END
    Create a ZIP file of the receipts  ${zipFileName}



