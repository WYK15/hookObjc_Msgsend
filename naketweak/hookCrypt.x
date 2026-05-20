#import "hookCrypt.h"
#include <substrate.h>
// https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/CCCryptorUpdate.3cc.html
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import "fishhook/fishhook.h"
#import <os/log.h>

static os_log_t hook_log = OS_LOG_DEFAULT;

// frida 版本： https://codeshare.frida.re/@Humenger/frida-ios-cipher/


// CCCryptorStatus
    //  CCCrypt(CCOperation op, CCAlgorithm alg, CCOptions options,
    //      const void *key, size_t keyLength, const void *iv,
    //      const void *dataIn, size_t dataInLength, void *dataOut,
    //      size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCrypt)(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv, const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus new_CCCrypt(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv, const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
    os_log(hook_log, "[HOOK] CCCrypt op: %d, alg: %d, options: %d, keyLength: %zu, iv: %p, dataInLength: %zu, dataOutAvailable: %zu", op, alg, options, keyLength, iv, dataInLength, dataOutAvailable);
    return orig_CCCrypt(op, alg, options, key, keyLength, iv, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}
void hook_CCCrypt(void) {
    MSHookFunction((void *)CCCrypt, (void *)new_CCCrypt, (void **)&orig_CCCrypt);
}

// //CCCryptorStatus CCCryptorCreateWithMode(
            //     CCOperation 	op,				/* kCCEncrypt, kCCEncrypt */
            //     CCMode			mode,
            //     CCAlgorithm		alg,
            //     CCPadding		padding,
            //     const void 		*iv,			/* optional initialization vector */
            //     const void 		*key,			/* raw key material */
            //     size_t 			keyLength,
            //     const void 		*tweak,			/* raw tweak material */  //for mode: XTS
            //     size_t 			tweakLength,
            //     int				numRounds,		/* 0 == default */
            //     CCModeOptions 	options,
            //     CCCryptorRef	*cryptorRef)	/* RETURNED */
CCCryptorStatus (*orig_CCCryptorCreateWithMode)(CCOperation op, CCMode mode, CCAlgorithm alg, CCPadding padding, const void *iv, const void *key, size_t keyLength, const void *tweak, size_t tweakLength, int numRounds, CCModeOptions options, CCCryptorRef *cryptorRef);
CCCryptorStatus new_CCCryptorCreateWithMode(CCOperation op, CCMode mode, CCAlgorithm alg, CCPadding padding, const void *iv, const void *key, size_t keyLength, const void *tweak, size_t tweakLength, int numRounds, CCModeOptions options, CCCryptorRef *cryptorRef) {
    os_log(hook_log, "[HOOK] CCCryptorCreateWithMode op: %d, mode: %d, alg: %d, padding: %d, iv: %p, keyLength: %zu, tweak: %p, tweakLength: %zu, numRounds: %d, options: %d", op, mode, alg, padding, iv, keyLength, tweak, tweakLength, numRounds, options);
    return orig_CCCryptorCreateWithMode(op, mode, alg, padding, iv, key, keyLength, tweak, tweakLength, numRounds, options, cryptorRef);
}
void hook_CCCryptorCreateWithMode(void){
    MSHookFunction((void *)CCCryptorCreateWithMode, (void *)new_CCCryptorCreateWithMode, (void **)&orig_CCCryptorCreateWithMode);
}


// CCCryptorStatus CCCryptorCreate(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef);
CCCryptorStatus (*orig_CCCryptorCreate)(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef);
CCCryptorStatus new_CCCryptorCreate(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef) {
    os_log(hook_log, "[HOOK] CCCryptorCreate op: %d, alg: %d, options: %d, keyLength: %zu, iv: %p", op, alg, options, keyLength, iv);
    return orig_CCCryptorCreate(op, alg, options, key, keyLength, iv, cryptorRef);
}
void hook_CCCryptorCreate(void) {
    MSHookFunction((void *)CCCryptorCreate, (void *)new_CCCryptorCreate, (void **)&orig_CCCryptorCreate);
}

//CCCryptorStatus CCCryptorUpdate(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCryptorUpdate)(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved);
CCCryptorStatus new_CCCryptorUpdate(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved) {
    os_log(hook_log, "[HOOK] CCCryptorUpdate cryptorRef: %p, dataInLength: %zu, dataOutAvailable: %zu", cryptorRef, dataInLength, dataOutAvailable);
    for(int index = 0; index < dataInLength; index += 900) {
       char buf[900];
       snprintf(buf, 900, "%s", (char *)dataIn + index);
       os_log(hook_log, "[HOOK] CCCryptorUpdate dataIn %d : %s", index + 1, buf);
    }
    
    return orig_CCCryptorUpdate(cryptorRef, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}
void hook_CCCryptorUpdate(void) {
    MSHookFunction((void *)CCCryptorUpdate, (void *)new_CCCryptorUpdate, (void **)&orig_CCCryptorUpdate);
}

//CCCryptorStatus CCCryptorFinal(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCryptorFinal)(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus new_CCCryptorFinal(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved) {
    os_log(hook_log, "[HOOK] CCCryptorFinal cryptorRef: %p, dataOutAvailable: %zu", cryptorRef, dataOutAvailable);
    return orig_CCCryptorFinal(cryptorRef, dataOut, dataOutAvailable, dataOutMoved);
}
void hook_CCCryptorFinal(void) {
    MSHookFunction((void *)CCCryptorFinal, (void *)new_CCCryptorFinal, (void **)&orig_CCCryptorFinal);
}

// CCHmac 函数
static void (*orig_CCHmac)(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data, size_t dataLength, void *dataOut);
static void new_CCHmac(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data, size_t dataLength, void *dataOut) {
    os_log(hook_log, "[HOOK] CCHmac called, keyLength: %zu, dataLength: %zu", keyLength, dataLength);
    return orig_CCHmac(algorithm, key, keyLength, data, dataLength, dataOut);
}
void hook_CCHmac(void) {
    MSHookFunction((void *)CCHmac, (void *)new_CCHmac, (void **)&orig_CCHmac);
}

// CCHmacUpdate 函数
static void (*orig_CCHmacUpdate)(CCHmacContext *ctx, const void *data, size_t dataLength);
static void new_CCHmacUpdate(CCHmacContext *ctx, const void *data, size_t dataLength) {
    os_log(hook_log, "[HOOK] CCHmacUpdate called, dataLength: %zu", dataLength);
    return orig_CCHmacUpdate(ctx, data, dataLength);
}
void hook_CCHmacUpdate(void) {
    MSHookFunction((void *)CCHmacUpdate, (void *)new_CCHmacUpdate, (void **)&orig_CCHmacUpdate);
}

// CC_MD5 函数
static void (*orig_CC_MD5)(const void *data, size_t dataLength, unsigned char *md);
static void new_CC_MD5(const void *data, size_t dataLength, unsigned char *md) {
    os_log(hook_log, "[HOOK] CC_MD5 called, dataLength: %zu", dataLength);
    return orig_CC_MD5(data, dataLength, md);
}
void hook_CC_MD5(void) {
    MSHookFunction((void *)CC_MD5, (void *)new_CC_MD5, (void **)&orig_CC_MD5);
}

// CC_MD5_Update 函数
static void (*orig_CC_MD5_Update)(CC_MD5_CTX *c, const void *data, size_t len);
static void new_CC_MD5_Update(CC_MD5_CTX *c, const void *data, size_t len) {
    os_log(hook_log, "[HOOK] CC_MD5_Update called, len: %zu", len);
    return orig_CC_MD5_Update(c, data, len);
}
void hook_CC_MD5_Update(void) {
    MSHookFunction((void *)CC_MD5_Update, (void *)new_CC_MD5_Update, (void **)&orig_CC_MD5_Update);
}
