#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifndef HOOKCRYPT_H
#define HOOKCRYPT_H

void hook_CCCrypt(void);

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
void hook_CCCryptorCreateWithMode(void);


// CCCryptorStatus CCCryptorCreate(CCOperation op, CCAlgorithm alg, CCOptions options, const void *key, size_t keyLength, const void *iv,CCCryptorRef *cryptorRef);
void hook_CCCryptorCreate(void);

//CCCryptorStatus CCCryptorUpdate(CCCryptorRef cryptorRef, const void *dataIn,size_t dataInLength, void *dataOut, size_t dataOutAvailable,size_t *dataOutMoved);
void hook_CCCryptorUpdate(void);

//CCCryptorStatus CCCryptorFinal(CCCryptorRef cryptorRef, void *dataOut,size_t dataOutAvailable, size_t *dataOutMoved);
void hook_CCCryptorFinal(void);

// CCHmac 函数
void hook_CCHmac(void);
void hook_CCHmacUpdate(void);

// CC_MD5 函数
void hook_CC_MD5(void);
void hook_CC_MD5_Update(void);

#endif /* HOOKCRYPT_H */
