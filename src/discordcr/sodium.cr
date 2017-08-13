module Discord
  # Bindings to libsodium. These aren't intended to be general bindings, just
  # for the specific xsalsa20poly1305 encryption Discord uses.
  @[Link("sodium")]
  lib Sodium
    # Encrypt something using xsalsa20poly1305
    fun crypto_secretbox_xsalsa20poly1305(c : UInt8*, message : UInt8*,
                                          mlen : UInt64, nonce : UInt8*,
                                          key : UInt8*) : LibC::Int

    # Decrypt something using xsalsa20poly1305 ("open a secretbox")
    fun crypto_secretbox_xsalsa20poly1305_open(message : UInt8*, c : UInt8*,
                                               mlen : UInt64, nonce : UInt8*,
                                               key : UInt8*) : LibC::Int

    # Constants
    fun crypto_secretbox_xsalsa20poly1305_keybytes : LibC::SizeT     # Key size in bytes
    fun crypto_secretbox_xsalsa20poly1305_noncebytes : LibC::SizeT   # Nonce size in bytes
    fun crypto_secretbox_xsalsa20poly1305_zerobytes : LibC::SizeT    # Zero bytes before a plaintext
    fun crypto_secretbox_xsalsa20poly1305_boxzerobytes : LibC::SizeT # Zero bytes before a ciphertext
  end
end
