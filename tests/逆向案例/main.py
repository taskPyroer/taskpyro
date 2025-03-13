import execjs

with open('decrypt-v.js', 'r') as f:
    jscontent = f.read()
context= execjs.compile(jscontent)


# 调用加密和解密函数
encrypted_message = context.call('encryptMessage', 'Hello, World!', 'secret-key')
print(f"Encrypted Message: {encrypted_message}")

decrypted_message = context.call('decryptMessage', encrypted_message, 'secret-key')
print(f"Decrypted Message: {decrypted_message}")