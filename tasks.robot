*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
Library             RPA.FileSystem


*** Variables ***
${order_number}
${GLOBAL_RETRY_AMOUNT}=         10x
${GLOBAL_RETRY_INTERVAL}=       1s
${PDF_Directory} =              ${CURDIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv    dialect=excel    header=True
    FOR    ${row}    IN    @{table}
        Log    ${row}
    END
    RETURN    ${table}

Fill the form
    [Arguments]    ${localrow}
    ${head}=    Convert To Integer    ${localrow}[Head]
    ${body}=    Convert To Integer    ${localrow}[Body]
    ${legs}=    Convert To Integer    ${localrow}[Legs]
    ${address}=    Convert To String    ${localrow}[Address]
    Select From List By Value    id:head    ${head}
    Click Element    id-body-${body}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs}
    Input Text    id:address    ${address}

Preview the robot
    Click Button    Preview

Submit the order And Keep Checking Until Success
    Click Element    order
    Element Should Be Visible    id:order-completion

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Submit the order And Keep Checking Until Success

Go to order another robot
    Click Button    order-another

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}order_im_${Order number}.png
    RETURN    ${OUTPUT_DIR}${/}order_im_${Order number}.png

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf
    RETURN    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${name_pdf}=    Get File Name    ${pdf}
    Add Watermark Image To PDF    ${screenshot}    ${PDF_Directory}${/}${name_pdf}    ${pdf}

    Close Pdf    ${pdf}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}recepts.zip
    Archive Folder With Zip    ${PDF_Directory}    ${zip_file_name}
