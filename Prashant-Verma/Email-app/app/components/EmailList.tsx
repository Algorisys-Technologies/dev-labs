import React from 'react';

interface Email {
  id: string;
  subject: string;
  from: string;
  to: string;
  date: string;
  bodyText: string;
}

interface EmailListProps {
  emails: Email[];
}

const EmailList: React.FC<EmailListProps> = ({ emails }) => {
  return (
    <ul>
      {emails.length > 0 ? (
        emails.map((email) => (
          <li key={email.id}>
            <h3>{email.subject}</h3>
            <p><strong>From:</strong> {email.from}</p>
            <p><strong>To:</strong> {email.to}</p>
            <p><strong>Date:</strong> {new Date(email.date).toLocaleString()}</p>
            <p>{email.bodyText}</p>
          </li>
        ))
      ) : (
        <p>No emails for this account</p>
      )}
    </ul>
  );
};

export default EmailList;
