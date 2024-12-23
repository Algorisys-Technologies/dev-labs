using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Security.Cryptography;
using System.Text;

namespace HelpDoc.Utilities
{
    public class EncryptionHelper : IEncryptionHelper
    {
        public string EncodePassword(string pass, int passwordFormat, string salt)
        {
            return SecurityUtil.EncodePassword(pass, passwordFormat, salt);
        }
    }

    public static class SecurityUtil
    {
        private static string HashName = "SHA1";

        internal static string GenerateSalt()
        {
            byte[] buf = new byte[16];
            (new RNGCryptoServiceProvider()).GetBytes(buf);
            return Convert.ToBase64String(buf);
        }

        //[CR 8]: Password encryption 
        internal static string EncodePassword(string pass, int passwordFormat, string salt)
        {
            if (passwordFormat == 0) // MembershipPasswordFormat.Clear
                return pass;

            byte[] bIn = Encoding.Unicode.GetBytes(pass);
            byte[] bSalt = Convert.FromBase64String(salt);
            byte[] bAll = new byte[bSalt.Length + bIn.Length];
            byte[] bRet = null;

            Buffer.BlockCopy(bSalt, 0, bAll, 0, bSalt.Length);
            Buffer.BlockCopy(bIn, 0, bAll, bSalt.Length, bIn.Length);
            if (passwordFormat == 1)
            { // MembershipPasswordFormat.Hashed
                HashAlgorithm s = HashAlgorithm.Create(HashName);
                bRet = s.ComputeHash(bAll);
            }
            else
            {
                bRet = (bAll);
            }
            return Convert.ToBase64String(bRet);
        }

    }
}