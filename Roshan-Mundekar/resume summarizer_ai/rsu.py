import openai
import fitz  # PyMuPDF

# Set OpenAI API key
openai.api_key = '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'  # Make sure to replace with your actual OpenAI API key

# Path to the PDF file (use the correct path)
pdf_path = "D:\\ALGORIS\\FINALCODEDEMO\\resume summarizer_ai\\Latest_code\\MainCode\\static\\uploads\\amit_2408.pdf"

# Function to extract text from the PDF using PyMuPDF
def extract_text_from_pdf(pdf_path):
    text = ""
    try:
        # Open the PDF file
        with fitz.open(pdf_path) as pdf_document:
            for page_num in range(len(pdf_document)):
                # Extract text from each page
                page = pdf_document[page_num]
                text += page.get_text()
    except Exception as e:
        print(f"Error reading PDF file: {str(e)}")
    return text

# Function to get an answer from OpenAI based on the PDF text and user's question
def get_openai_answer(extracted_text, question):
    try:
        # Define the max token limit (conservatively lower than the actual limit)
        max_chunk_size = 3000  # Adjust as needed, considering both input and response

        # Split the extracted text into smaller chunks
        chunks = [extracted_text[i:i+max_chunk_size] for i in range(0, len(extracted_text), max_chunk_size)]

        full_answer = ""
        for chunk in chunks:
            # Combine the chunk of text and the user's question into a prompt
            prompt = f"""
            You are a helpful assistant. You are given the following text extracted from a PDF document:

            {chunk}

            Answer the following question based on the above text:
            {question}
            """

            # Call OpenAI's new chat API format (chat-based completion)
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",  # You can also use 'gpt-3.5-turbo' if needed
                messages=[
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=2000,  # Leave enough space for the answer
                temperature=0.0,  # Lower temperature gives more deterministic results
            )

            # Extract the answer from the API response
            answer = response['choices'][0]['message']['content'].strip()
            full_answer += answer + "\n\n"

        return full_answer.strip()

    except Exception as e:
        print(f"Error communicating with OpenAI: {str(e)}")
        return "Sorry, I couldn't find an answer to your question."


# Main function to extract text from PDF and ask a question
# if __name__ == "__main__":
#     # Extract text from the PDF file
#     extracted_text = extract_text_from_pdf(pdf_path)

#     # Example question
#     search_phrase = "Which design software tools does Paisley Moore have experience with?"

#     # Get the answer from OpenAI by passing the extracted text and the question
#     if extracted_text:
#         answer = get_openai_answer(extracted_text, search_phrase)

#         # Print the answer
#         print("Question:", search_phrase)
#         print("Answer:", answer)
#     else:
#         print("Could not extract text from the PDF.")
