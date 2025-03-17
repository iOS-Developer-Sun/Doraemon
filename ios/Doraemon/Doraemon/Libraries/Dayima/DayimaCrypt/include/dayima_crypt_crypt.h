#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * @param uid 用户id
 * @param data 待加密数据
 * @param data_len 待加密数据大小，字节计
 * @param result 返回的加密完的密串，32字节长度，后面追加一个'\0'
 */
extern void dayima_crypt_encrypt_data(long long uid, const unsigned char *data, long long data_len, char result[33]);
