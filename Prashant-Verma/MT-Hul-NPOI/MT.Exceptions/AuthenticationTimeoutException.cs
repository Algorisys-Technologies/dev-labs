using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace MT.Exceptions
{
    [Serializable]
    public class AuthenticationTimeoutException : System.Exception
    {
        public AuthenticationTimeoutException()
        {
        }

        public AuthenticationTimeoutException(string message)
            : base(message)
        {
        }

        public AuthenticationTimeoutException(string errorMessage, Exception innerException)
            : base(errorMessage, innerException)
        {
        }

        protected AuthenticationTimeoutException(SerializationInfo si, StreamingContext sc)
            : base(si, sc)
        {
        }
    }
}
