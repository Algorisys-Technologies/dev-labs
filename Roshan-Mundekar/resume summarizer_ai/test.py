# extracted_data = {
#     "full_name": "RUSHIKESH BELKUNDE",
#     "email_id": "rushibelkunde18@gmail.com",
#     "github_portfolio": "Github.com/rushibelkunde",
#     "linkedin_id": "Linkedin/rushibelkunde",
#     "employment_details": [
#         {
#             "title": "Full Stack Web Developer",
#             "duration": "9 months",
#             "company": "Coding Ninjas"
#         }
#     ],
#     "technical_skills": {
#         "programming_languages": ["Java", "Python"],
#         "frontend": ["HTML", "CSS", "TailwindCSS", "JavaScript", "React"],
#         "backend": ["NodeJS", "Express", "NextJs"],
#         "database": ["MongoDB", "SQL", "Firebase"],
#         "version_control": ["Git/Github"]
#     },
#     "soft_skills": [
#         "problem solving",
#         "web design",
#         "full project management",
#         "data structures and algorithms",
#         "designing",
#         "verbal communication",
#         "analytical"
#     ]
# }

# def find_answer(question, extracted_data):
#     question_lower = question.lower()
#     best_answer = "I'm sorry, but I couldn't find an answer to your question."
#     highest_score = 0

#     def search(data):
#         nonlocal highest_score, best_answer
#         score = 0
        

#         if isinstance(data, dict):
#             for key, value in data.items():
#                 if key.lower() in question_lower:  # Exact match for keys
#                     score += 2
#                     if isinstance(value, list) or isinstance(value, dict):
#                         best_answer = value
#                     else:
#                         best_answer = f"{key}: {value}"
#                 search(value)
#         elif isinstance(data, list):
#             for item in data:
#                 search(item)
#         elif isinstance(data, str):
#             if data.lower() in question_lower:  # Exact match for values
#                 score += 1
#                 best_answer = data

#         if score > highest_score:
#             highest_score = score

#     search(extracted_data)
#     return best_answer

# # Example questions
# questions = [
#     "What programming_languages do?",
#     "What are your frontend skills?",
#     "What is your job title?",
#     "What are your soft_skills?",
#     "What is your employment_details?"
# ]

# for question in questions:
#     print(type(question))
#     answer = find_answer(question, extracted_data)
#     print(f"Question: {question}")
#     print(f"Answer: {answer}")
#     print()


import json


# Sample JSON data
json_data = {
    "full_name": "RUSHIKESH BELKUNDE",
    "email_id": "rushibelkunde18@gmail.com",
    "github_portfolio": "Github.com/rushibelkunde",
    "linkedin_id": "Linkedin/rushibelkunde",
    "employment_details": [
        {
            "title": "Full Stack Web Developer",
            "duration": "9 months",
            "company": "Coding Ninjas"
        }
    ],
    "technical_skills": {
        "programming_languages": ["Java", "Python"],
        "frontend": ["HTML", "CSS", "TailwindCSS", "JavaScript", "React"],
        "backend": ["NodeJS", "Express", "NextJs"],
        "database": ["MongoDB", "SQL", "Firebase"],
        "version_control": ["Git/Github"]
    },
    "soft_skills": [
        "problem solving",
        "web design",
        "full project management",
        "data structures and algorithms",
        "designing",
        "verbal communication",
        "analytical"
    ]
}

# Function to search for words in JSON and return related values
def search_in_json(data, search_words):
    matches = []

    if isinstance(data, dict):
        for key, value in data.items():
            if any(word.lower() in key.lower() for word in search_words):
                if isinstance(value, list):
                    matches.extend(value)  # Add values from the list directly
                else:
                    matches.append(value)  # Add the value directly if not a list
            # Recursive search in value
            matches.extend(search_in_json(value, search_words))
    
    elif isinstance(data, list):
        for item in data:
            matches.extend(search_in_json(item, search_words))
    
    elif isinstance(data, str):
        if any(word.lower() in data.lower() for word in search_words):
            matches.append(data)

    return matches

# Search for words in the JSON data
search_phrase = "What programming languages do?"
print(json_data)
print(type(json_data))
search_words = search_phrase.split()  # Split the phrase into words
results = search_in_json(json_data, search_words)

print(results)

# # Print the results
# if results:
#     print(f"Search results for '{search_phrase}':")
#     for match in results:
#         print(match)  # Print only the values
# else:
#     print(f"No matches found for '{search_phrase}'.")






