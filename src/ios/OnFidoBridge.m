#import "OnFidoBridge.h"

#import <Cordova/CDVAvailability.h>
#import <Onfido/Onfido-Swift.h>

@implementation OnFidoBridge

- (void)pluginInitialize {
}

- (void)init: (CDVInvokedUrlCommand *)command {
    NSDictionary* options = [command.arguments objectAtIndex:0];
    NSString* token = [options objectForKey:@"token"];
    //NSString* locale = [options objectForKey:@"locale"];

    ONFlowConfigBuilder *configBuilder = [ONFlowConfig builder];


    [configBuilder withSdkToken:token];
    [configBuilder withWelcomeStep];
    //[configBuilder withDocumentStep];

    NSError *variantError = NULL;
    Builder *variantBuilder = [ONFaceStepVariantConfig builder];
    [variantBuilder withPhotoCaptureWithConfig: NULL];
    [configBuilder withFaceStepOfVariant: [variantBuilder buildAndReturnError: &variantError]];
    
    NSError *documentVariantError = NULL;
    DocumentConfigBuilder *documentVariantBuilder = [ONDocumentTypeVariantConfig builder];
    [documentVariantBuilder withNationalIdentityCardWithConfig:[[NationalIdentityConfiguration alloc] initWithCountry: @"AGO"]];
    [configBuilder withDocumentStepOfType:[documentVariantBuilder buildAndReturnError: &documentVariantError]];
    
    //UI
    ONAppearance *appearance = [[ONAppearance alloc] init];
    appearance.primaryColor = [UIColor colorWithRed: 0.94 green: 0.36 blue: 0.10 alpha: 1.00];
    appearance.primaryBackgroundPressedColor = [UIColor colorWithRed: 0.94 green: 0.36 blue: 0.10 alpha: 1.00];
    appearance.secondaryBackgroundPressedColor = [UIColor colorWithRed: 0.94 green: 0.36 blue: 0.10 alpha: 1.00];
    [configBuilder withAppearance:appearance];
    
    //Locale
//    if (locale != NULL){
//        NSString * path = [[NSBundle bundleForClass:[ONFlowConfig class]] pathForResource:locale ofType:@"lproj"];
//        NSBundle * bundle = nil;
//        if(path == nil){
//            bundle = [NSBundle mainBundle];
//        }else{
//            bundle = [NSBundle bundleWithPath:path];
//        }
//        //[configBuilder withCustomLocalizationWithTableName:@"Localizable" in: bundle];
//        [configBuilder withCustomLocalizationWithTableName:@"Localizable_PT"];
//    }
    
    //Set PT Locale Strings
    [configBuilder withCustomLocalizationWithTableName:@"Localizable_PT"];
    
    if(variantError != NULL)
    {
        [self handleConfigsError:variantError :command.callbackId];
        return;
    }
    
    
    if (variantError == NULL) {
      NSError *configError = NULL;
      ONFlowConfig *config = [configBuilder buildAndReturnError:&configError];

        
        if (configError == NULL) {
                ONFlow *onFlow = [[ONFlow alloc] initWithFlowConfiguration:config];

                [onFlow withResponseHandler:^(ONFlowResponse* response){
                    [self handleOnFidoCallback: response :command.callbackId];
                }];

                NSError *runError = NULL;
                UIViewController *onfidoController = [onFlow runAndReturnError:&runError];

                if (runError == NULL) {
                    [self.viewController presentViewController:onfidoController animated:YES completion:NULL];
                } else {
                    [self showAlert:@"Error occured during Onfido flow. Look for details in console"];
                }
            } else
                [self handleConfigsError:configError :command.callbackId];
      }
}

#pragma mark - "Private methods"

- (NSString*) buildDocumentJson: (NSArray*) documentsResult {

    NSMutableDictionary *documentKeyValue =  [[NSMutableDictionary alloc] initWithCapacity:2];

    ONDocumentResult* front = ((ONFlowResult*) documentsResult[0]).result;
    NSDictionary* frontKeyValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                   front, @"id",
                                   front, @"side",
                                   front, @"type",
                                   nil];

    [documentKeyValue setObject:frontKeyValue forKey:@"front"];

    if (([documentsResult count] > 1 && [documentsResult objectAtIndex:1] !=nil)) {
        ONDocumentResult* back = ((ONFlowResult*) documentsResult[1]).result;
        NSDictionary* backKeyValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                      back, @"id",
                                      back, @"side",
                                      back, @"type",
                                      nil];
        [documentKeyValue setObject:backKeyValue forKey:@"back"];
    }

    NSDictionary* resultKeyValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                    documentKeyValue, @"document",
                                    nil];
    NSError* error;
    NSData* json = [NSJSONSerialization dataWithJSONObject:resultKeyValue options:NSJSONWritingPrettyPrinted error:&error];

    return [[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding];
}

- (void)handleOnFidoCallback: (ONFlowResponse*) response : (id) callbackId {
    if(response.userCanceled) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"0"];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    } else if(response.results) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"1"];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];

    } else if(response.error) {
        //something went wrong
        [self handleOnFlowError: response.error :callbackId];
    }
    [self.viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleConfigsError: (NSError*) error : (id) callbackId {
    NSString* errMsg;
    switch (error.code) {
        /*case ONFlowConfigErrorMissingSDKToken:
            errMsg = @"No token provided";
            break;
        case ONFlowConfigErrorMissingSDKToken:
            errMsg = @"No applicant provided";
            break;
        case ONFlowConfigErrorMissingSteps:
            errMsg = @"No steps provided";
            break;
        case ONFlowConfigErrorMultipleApplicants:
            errMsg = @"Failed to upload capture";
            break;*/
        default:
            errMsg = [NSString stringWithFormat:@"Unknown error occured. Code: %ld. Description: %@", error.code, error.description];
            break;
    }

    NSLog(@"%@", errMsg);
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];

    [self.viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleOnFlowError: (NSError*) error : (id) callbackId{
    NSString* errMsg;
    switch (error.code) {
        case ONFlowErrorCameraPermission:
            errMsg = @"Onfido sdk does not have camera permissions";
            break;
        case ONFlowErrorFailedToWriteToDisk:
            errMsg = @"Onfido sdk failed to save capture to disk. May be due to a lack of space";
            break;
        case ONFlowErrorMicrophonePermission:
            errMsg = @"Onfido sdk does not have microphone permissions";
            break;
        case ONFlowErrorUpload:
            errMsg = @"Failed to upload capture";
            break;
        case ONFlowErrorException:
            errMsg = [NSString stringWithFormat: @"Unexpected error occured. Code: %ld. Description: %@", error.code,
                      error.description];
            break;
        default:
            errMsg = [NSString stringWithFormat: @"Unknown error occured. Code: %ld. Description: %@", error.code,
                      error.description];
            break;
    }
    NSLog(@"%@", errMsg);
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)showAlert:(NSString*) msg {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:nil];

    [alert addAction:defaultAction];

    [self.viewController presentViewController:alert animated:YES completion:nil];
}

@end
