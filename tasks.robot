*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}temp

*** Tasks ***
Minimal task
    Log    Done.

Order robots from RobotSpareBin Industries Inc
    Set up directories
    Download the CSV file
    Read CSV file
    Open the robot order website
    Make the orders
    Create ZIP package from PDF files
    [Teardown]    Finish the process

*** Keywords ***
Collect the secrets
    ${secret}=    Get Secret    urls_process
    [Return]    ${secret}

Collect the data
    Add text input    data    label=Robots order data (url)
    ${response}=    Run dialog
    [Return]    ${response.data}

Open the robot order website
    ${secret_variables}=    Collect the secrets
    Open Available Browser    ${secret_variables}[robot_orders_urls]

Download the CSV file
    ${url}=    Collect the data
    Download    ${url}    overwrite=True

Read CSV file
    Wait Until Keyword Succeeds    2x    5s    File Should Exist    ${CURDIR}/orders.csv
    ${data}=    Read table from CSV    ${CURDIR}/orders.csv    header=True
    [Return]    ${data}

Make the orders
    ${orders}=    Read CSV file
    FOR    ${order}    IN    @{orders}
        # filling the form with data
        Fill the form    ${order}
        # sending the form
        Wait Until Keyword Succeeds    5x    10s    Send order
        # saving the order with resume and robot image
        Wait Until Keyword Succeeds    5x    5s    Save order as PDF
        # make another order
        Click Button    id:order-another
    END

Fill the form
    [Arguments]    ${robot}
    # removing the modal
    Wait Until Element Is Visible    id:root    50
    Click Button    xpath: //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    # filling the form
    Select From List By Value    id:head    ${robot}[Head]
    Click Element    id:id-body-${robot}[Body]
    Input Text    xpath: /html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${robot}[Legs]
    Input Text    id:address    ${robot}[Address]
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot.jpeg

Save order as PDF
    # get info order
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    # set nam
    ${file_name}=    Get Element Attribute    xpath: //*[@id="receipt"]/p[1]    outerText
    Html To Pdf    ${receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${file_name}.pdf
    Open Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${file_name}.pdf
    ${new_pdf}=    Create List    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${file_name}.pdf    ${OUTPUT_DIR}${/}robot.jpeg:x=30,y=20
    Add Files To Pdf    ${new_pdf}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${file_name}.pdf
    Close Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${file_name}.pdf

Send order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Robot_Orders.zip
    Archive Folder With Zip    ${PDF_TEMP_OUTPUT_DIRECTORY}    ${zip_file_name}

Finish the process
    Close Browser
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True
