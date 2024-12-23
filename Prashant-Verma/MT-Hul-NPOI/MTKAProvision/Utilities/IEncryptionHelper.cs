using System;
namespace HelpDoc.Utilities
{
    public interface IEncryptionHelper
    {
        string EncodePassword(string pass, int passwordFormat, string salt);
    }
}
