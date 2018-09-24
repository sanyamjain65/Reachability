#import "CallCFunction.h"
#import <AVFoundation/AVFoundation.h>

@interface PJSUAWrapper :NSObject {
    
    // pjsua_acc_id acc_id;
    
    
    pj_status_t status;
    AVAudioPlayer* audioPlayer;
    
    char * UsercallID ;
    NSString * UserID ;
    int count  ;
    
    
}



@property(nonatomic,assign)   pjsua_call_id call_id ;


@property(strong , nonatomic)  NSString * callData;

// The hooks for our plugin commands
- (NSString *)start;
- (void)stop;
- (void)hangup;
- (void)mute;
- (void)unmute;
- (void)speakeron;
- (void)speakeroff;
- (void)playRingtone;
- (void)requestPermission;

void answercall(void);
@end
