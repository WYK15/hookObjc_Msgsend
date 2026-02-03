#import "hookCrypt.h"
#include <substrate.h>
// https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/CCCryptorUpdate.3cc.html
#import <CommonCrypto/CommonCryptor.h>
#import "fishhook/fishhook.h"

// frida 版本： https://codeshare.frida.re/@Humenger/frida-ios-cipher/


// CCCryptorStatus
    //  CCCrypt(CCOperation op, CCAlgorithm alg, CCOptions options,
    //      const void *key, size_t keyLength, const void *iv,
    //      const void *dataIn, size_t dataInLength, void *dataOut,
    //      size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCrypt)(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv, const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus new_CCCrypt(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv, const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
    NSLog(@"[HOOK] CCCrypt op: %d, alg: %d, options: %d, keyLength: %zu, iv: %p, dataInLength: %zu, dataOutAvailable: %zu", op, alg, options, keyLength, iv, dataInLength, dataOutAvailable);
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
    NSLog(@"[HOOK] CCCryptorCreateWithMode op: %d, mode: %d, alg: %d, padding: %d, iv: %p, keyLength: %zu, tweak: %p, tweakLength: %zu, numRounds: %d, options: %d", op, mode, alg, padding, iv, keyLength, tweak, tweakLength, numRounds, options);
    return orig_CCCryptorCreateWithMode(op, mode, alg, padding, iv, key, keyLength, tweak, tweakLength, numRounds, options, cryptorRef);
}
void hook_CCCryptorCreateWithMode(void){
    MSHookFunction((void *)CCCryptorCreateWithMode, (void *)new_CCCryptorCreateWithMode, (void **)&orig_CCCryptorCreateWithMode);
}


// CCCryptorStatus CCCryptorCreate(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef);
CCCryptorStatus (*orig_CCCryptorCreate)(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef);
CCCryptorStatus new_CCCryptorCreate(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef) {
    NSLog(@"[HOOK] CCCryptorCreate op: %d, alg: %d, options: %d, keyLength: %zu, iv: %p", op, alg, options, keyLength, iv);
    return orig_CCCryptorCreate(op, alg, options, key, keyLength, iv, cryptorRef);
}
void hook_CCCryptorCreate(void) {
    MSHookFunction((void *)CCCryptorCreate, (void *)new_CCCryptorCreate, (void **)&orig_CCCryptorCreate);
}

//CCCryptorStatus CCCryptorUpdate(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCryptorUpdate)(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved);
CCCryptorStatus new_CCCryptorUpdate(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved) {
    NSLog(@"[HOOK] CCCryptorUpdate cryptorRef: %p, dataInLength: %zu, dataOutAvailable: %zu", cryptorRef, dataInLength, dataOutAvailable);
    for(int index = 0; index < dataInLength; index += 900) {
       char buf[900];
       snprintf(buf, 900, "%s", (char *)dataIn + index);
       NSLog(@"[HOOK] CCCryptorUpdate dataIn %d : %s, ", index + 1, buf);
    }
    
    return orig_CCCryptorUpdate(cryptorRef, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}
void hook_CCCryptorUpdate(void) {
    MSHookFunction((void *)CCCryptorUpdate, (void *)new_CCCryptorUpdate, (void **)&orig_CCCryptorUpdate);
}

//CCCryptorStatus CCCryptorFinal(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus (*orig_CCCryptorFinal)(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved);
CCCryptorStatus new_CCCryptorFinal(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved) {
    NSLog(@"[HOOK] CCCryptorFinal cryptorRef: %p, dataOutAvailable: %zu", cryptorRef, dataOutAvailable);
    return orig_CCCryptorFinal(cryptorRef, dataOut, dataOutAvailable, dataOutMoved);
}
void hook_CCCryptorFinal(void) {
    MSHookFunction((void *)CCCryptorFinal, (void *)new_CCCryptorFinal, (void **)&orig_CCCryptorFinal);
}
