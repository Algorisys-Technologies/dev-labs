using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace MT.Exceptions
{
    [Serializable]
    public class XMLFileNotFoundException: System.Exception
    {
        public XMLFileNotFoundException()
        {
        }

        public XMLFileNotFoundException(string message)
            : base(message)
        {
        }

        public XMLFileNotFoundException(string errorMessage, Exception innerException)
            : base(errorMessage, innerException)
        {
        }

        protected XMLFileNotFoundException(SerializationInfo si, StreamingContext sc)
            : base(si, sc)
        {
        }
    }
}