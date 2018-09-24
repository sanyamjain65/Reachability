#import "PJSUAWrapper.h"
#import <AVFoundation/AVFoundation.h>


@implementation PJSUAWrapper : NSObject


pj_status_t status;
static pjsua_acc_id acc_id;
pjsua_call_id callId  ;
pjsua_call_info ci;
- (NSString *) start {
    @try {
        NSString *num = @"917042437761";
        NSString *host =  @"sphere.patchus.in";
        status = pjsua_create();
        if (status != PJ_SUCCESS) error_exit("Error in pjsua_create()", status);
        /* Init pjsua */
        pjsua_config cfg_log;
        pjsua_logging_config log_cfg;
        pjsua_config_default(&cfg_log);
        cfg_log.cb.on_incoming_call = &on_incoming_call;
        cfg_log.cb.on_call_media_state = &on_call_media_state;
        cfg_log.cb.on_call_state = &on_call_state;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
        status = pjsua_init(&cfg_log, &log_cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error in pjsua_init()", status);
        pjsua_transport_config  tcfg;
        pjsua_transport_config_default(&tcfg);
        tcfg.port = 7503;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &tcfg, NULL);
        status = pjsua_start();
        if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
        /* Register to SIP server by creating SIP account. */
        NSString *string1 = @"sip:";
        NSString *string2 = @"@";
        NSString *string3 = @":7503;transport=tcp";
        NSString *string4 = @";transport=tcp";
        NSString *uri = [string1 stringByAppendingString:num];
        NSString *reg = [string2 stringByAppendingString:host];
        NSString *newUri = [uri stringByAppendingString:reg];
        NSString *proxy = [string1 stringByAppendingString:host];
        NSString *reg_uri = [proxy stringByAppendingString:string4];
        proxy = [proxy stringByAppendingString:string3];
        const char *c = [newUri UTF8String];
        const char *r = [reg_uri UTF8String];
        const char *p = [proxy UTF8String];
        const char *number = [num UTF8String];
        pjsua_acc_config cfg;
        pjsua_acc_config_default(&cfg);
        cfg.id = pj_str(c);
        cfg.reg_uri = pj_str(r);
        cfg.proxy[cfg.proxy_cnt++] = pj_str(p);
        cfg.cred_count = 1;
        cfg.cred_info[0].realm = pj_str("*");
        cfg.cred_info[0].scheme = pj_str("digest");
        cfg.cred_info[0].username = pj_str(number);
        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        cfg.cred_info[0].data = pj_str("patch");
        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        
        //    if (status != PJ_SUCCESS) error_exit("Error adding account", status);
        if (status == PJ_SUCCESS) {
            NSString *response = @"SUCCESS";
            return response;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        NSString *response = @"failed";
        return response;
    }
}


static void error_exit(const char *title, pj_status_t status)
{
    pjsua_perror("App", title, status);
    pjsua_destroy();
    exit(1);
}


static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    PJ_UNUSED_ARG(e);
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,("App", "Call %d state=%.*s", call_id,
              (int)ci.state_text.slen,
              ci.state_text.ptr));
    
}

static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_get_info(call_id, &ci);
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
    if (ci.media_status == PJSUA_CALL_MEDIA_NONE) {
        pjsua_conf_disconnect(ci.conf_slot, 0);
    }
}

- (void)requestPermission {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        NSString *status = @"";
        if (granted) {
            status = @"granted";
            NSLog(@"Permission granted");
        }
        else {
            status = @"not granted";
            NSLog(@"Permission denied");
        }
        
    }];
}

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,("App", "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,
              ci.remote_info.ptr));
    setCallid(call_id) ;
    pjsua_call_answer(call_id, 200, NULL, NULL);
}

pjsua_call_id getCallid(){
    
    return  callId  ;
    
}

void setCallid(pjsua_call_id callid){
    
    callId  = callid  ;
    
}
void answercall () {
    pjsua_call_id call_id  = getCallid();
    printf("call id in  hangup     :   %d", call_id) ;
    
    pjsua_call_answer(call_id, 200, NULL, NULL);
}

- (void)hangup{
    pjsua_call_id call_id  =  getCallid();
    printf("call id   : %d", call_id) ;
    pjsua_call_hangup(call_id, 200, NULL, NULL);
    
}

- (void)speakeron
{
    BOOL success;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
                             error:&error];
    if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (!success) NSLog(@"AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error setActive: %@", [error localizedDescription]);
    
}

- (void)speakeroff
{
    BOOL success;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
                             error:&error];
    if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    if (!success) NSLog(@"AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error setActive: %@", [error localizedDescription]);
    
}

- (void)unmute
{
    pjsua_conf_adjust_tx_level(ci.conf_slot , 1);
    
}
- (void)mute
{
    pjsua_conf_adjust_tx_level(ci.conf_slot , 0) ;
    
}


- (void)stop
{
    pjsua_call_hangup_all();
    pjsua_destroy();
    
}

- (void)playRingtone
{
    NSURL *fileURL = [NSURL URLWithString:@"assets/tones/outgoing.mp3"]; // see list below
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL,&soundID);
    AudioServicesPlaySystemSound(soundID);
}



@end
