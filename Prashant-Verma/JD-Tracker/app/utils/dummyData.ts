// Dummy data for HRMS
export const employees = [
  { id: 1, name: "John Doe", email: "john.doe@example.com", position: "Software Developer", department: "IT", joinDate: "2022-01-15", status: "Active" },
  { id: 2, name: "Jane Smith", email: "jane.smith@example.com", position: "HR Manager", department: "HR", joinDate: "2021-07-01", status: "Active" },
  { id: 3, name: "Robert Brown", email: "robert.brown@example.com", position: "QA Engineer", department: "IT", joinDate: "2023-03-22", status: "Active" },
  { id: 4, name: "Emily Davis", email: "emily.davis@example.com", position: "Project Manager", department: "Operations", joinDate: "2020-12-12", status: "Inactive" },
  { id: 5, name: "David Wilson", email: "david.wilson@example.com", position: "Product Owner", department: "Product", joinDate: "2022-05-10", status: "Active" },
  { id: 6, name: "Laura Johnson", email: "laura.johnson@example.com", position: "Designer", department: "Creative", joinDate: "2021-09-05", status: "Active" },
  { id: 7, name: "Kevin Miller", email: "kevin.miller@example.com", position: "Accountant", department: "Finance", joinDate: "2019-11-28", status: "Active" },
  { id: 8, name: "Sophia Lee", email: "sophia.lee@example.com", position: "Intern", department: "IT", joinDate: "2024-02-01", status: "Active" },
  { id: 9, name: "Brian Taylor", email: "brian.taylor@example.com", position: "DevOps Engineer", department: "IT", joinDate: "2023-08-19", status: "Active" },
  { id: 10, name: "Olivia Martin", email: "olivia.martin@example.com", position: "Recruiter", department: "HR", joinDate: "2023-10-15", status: "Active" },
];

export const attendanceRecords = [
  { id: 1, employeeId: 1, date: "2023-06-01", inTime: "09:00", outTime: "17:30", status: "Present" },
  { id: 2, employeeId: 1, date: "2023-06-02", inTime: "09:15", outTime: "17:45", status: "Present" },
  { id: 3, employeeId: 1, date: "2023-06-03", inTime: "", outTime: "", status: "Weekend" },
  { id: 4, employeeId: 1, date: "2023-06-04", inTime: "", outTime: "", status: "Weekend" },
  { id: 5, employeeId: 1, date: "2023-06-05", inTime: "08:45", outTime: "17:15", status: "Present" },
  { id: 6, employeeId: 2, date: "2023-06-01", inTime: "09:00", outTime: "18:00", status: "Present" },
  { id: 7, employeeId: 2, date: "2023-06-02", inTime: "09:10", outTime: "18:10", status: "Present" },
  { id: 8, employeeId: 3, date: "2023-06-01", inTime: "", outTime: "", status: "Leave" },
  { id: 9, employeeId: 4, date: "2023-06-01", inTime: "10:00", outTime: "17:00", status: "Present" },
  { id: 10, employeeId: 5, date: "2023-06-01", inTime: "09:05", outTime: "17:35", status: "Present" },
];

export const leaveApplications = [
  { id: 1, employeeId: 1, startDate: "2023-06-10", endDate: "2023-06-12", type: "Annual", status: "Approved" },
  { id: 2, employeeId: 2, startDate: "2023-07-05", endDate: "2023-07-07", type: "Sick", status: "Pending" },
  { id: 3, employeeId: 3, startDate: "2023-08-01", endDate: "2023-08-02", type: "Casual", status: "Rejected" },
  { id: 4, employeeId: 4, startDate: "2023-09-15", endDate: "2023-09-17", type: "Annual", status: "Approved" },
  { id: 5, employeeId: 5, startDate: "2023-06-20", endDate: "2023-06-22", type: "Casual", status: "Approved" },
  { id: 6, employeeId: 6, startDate: "2023-10-01", endDate: "2023-10-05", type: "Sick", status: "Pending" },
  { id: 7, employeeId: 7, startDate: "2023-11-12", endDate: "2023-11-13", type: "Casual", status: "Approved" },
  { id: 8, employeeId: 8, startDate: "2023-12-24", endDate: "2023-12-26", type: "Annual", status: "Pending" },
  { id: 9, employeeId: 9, startDate: "2023-12-30", endDate: "2024-01-02", type: "Annual", status: "Approved" },
  { id: 10, employeeId: 10, startDate: "2023-06-15", endDate: "2023-06-16", type: "Casual", status: "Approved" },
];

// Dummy data for JD Tracker
export const jdEntries = [
  {
    id: 1,
    jdId: "AB1234",
    title: "Frontend Developer",
    description: "We are looking for a skilled Frontend Developer to join our team. You will be responsible for building user interfaces and implementing design systems using modern web technologies.",
    department: "Engineering",
    location: "San Francisco, CA",
    employmentType: "Full-time",
    experienceLevel: "Mid",
    status: "Active",
    createdAt: "2023-05-15",
    ctcRange: "$90,000 - $120,000",
    qualifications: [
      "Bachelor's degree in Computer Science or related field",
      "3+ years of professional frontend development experience"
    ],
    responsibilities: [
      "Develop responsive user interfaces using React",
      "Implement design systems with attention to detail",
      "Optimize application performance",
      "Collaborate with UX designers and backend developers"
    ],
    requirements: [
      "3+ years of React experience",
      "Strong JavaScript/TypeScript skills",
      "Experience with modern CSS frameworks",
      "Familiarity with RESTful APIs"
    ],
    skills: ["React", "TypeScript", "CSS", "HTML", "Redux"],
    benefits: [
      "Health insurance",
      "401(k) matching",
      "Flexible work hours",
      "Remote work options"
    ]
  },
  {
    id: 2,
    jdId: "GG2345",
    title: "Backend Engineer",
    description: "Join our backend engineering team to build scalable and reliable services that power our platform. You'll work with modern technologies to design and implement APIs and microservices.",
    department: "Engineering",
    location: "Remote",
    employmentType: "Full-time",
    experienceLevel: "Senior",
    status: "Active",
    createdAt: "2023-06-20",
    ctcRange: "$110,000 - $150,000",
    qualifications: [
      "Bachelor's or Master's in Computer Science",
      "5+ years of backend development experience"
    ],
    responsibilities: [
      "Design and implement scalable backend services",
      "Optimize database performance",
      "Implement security best practices",
      "Mentor junior engineers"
    ],
    requirements: [
      "Expertise in Node.js or Python",
      "Experience with cloud platforms (AWS/GCP)",
      "Strong database design skills",
      "Knowledge of containerization and orchestration"
    ],
    skills: ["Node.js", "Python", "AWS", "Docker", "PostgreSQL"],
    benefits: [
      "Competitive salary",
      "Unlimited PTO",
      "Home office stipend",
      "Professional development budget"
    ]
  },
  {
    id: 3,
    jdId: "IT3456",
    title: "UX Designer",
    description: "We're seeking a creative UX Designer to create intuitive and beautiful user experiences for our products. You'll conduct user research, create wireframes, and collaborate with developers.",
    department: "Design",
    location: "New York, NY",
    employmentType: "Full-time",
    experienceLevel: "Mid",
    status: "Active",
    createdAt: "2023-07-10",
    ctcRange: "$85,000 - $110,000",
    qualifications: [
      "Degree in Design, HCI, or related field",
      "Portfolio demonstrating UX design skills"
    ],
    responsibilities: [
      "Conduct user research and testing",
      "Create wireframes and prototypes",
      "Collaborate with product managers",
      "Develop design systems"
    ],
    requirements: [
      "3+ years of UX design experience",
      "Proficiency with Figma/Sketch",
      "Understanding of frontend technologies",
      "Strong communication skills"
    ],
    skills: ["Figma", "User Research", "Prototyping", "UI Design", "Accessibility"],
    benefits: [
      "Health and wellness benefits",
      "Flexible schedule",
      "Annual design conference budget",
      "Creative work environment"
    ]
  },
  {
    id: 4,
    jdId: 4567,
    title: "Data Scientist",
    description: "Join our data team to extract insights from large datasets and build machine learning models that drive business decisions. You'll work with stakeholders across the company.",
    department: "Data Science",
    location: "Boston, MA",
    employmentType: "Full-time",
    experienceLevel: "Senior",
    status: "Active",
    createdAt: "2023-08-05",
    ctcRange: "$120,000 - $160,000",
    qualifications: [
      "PhD or Master's in Statistics, CS, or related field",
      "Experience with machine learning in production"
    ],
    responsibilities: [
      "Develop predictive models",
      "Analyze large datasets",
      "Communicate findings to stakeholders",
      "Optimize data pipelines"
    ],
    requirements: [
      "Python/R expertise",
      "Experience with SQL and NoSQL databases",
      "Knowledge of ML frameworks",
      "Strong statistical background"
    ],
    skills: ["Python", "Machine Learning", "TensorFlow", "SQL", "Data Visualization"],
    benefits: [
      "Stock options",
      "Generous bonus structure",
      "Research publication support",
      "Conference attendance"
    ]
  },
  {
    id: 5,
    jdId: 5678,
    title: "Product Manager",
    description: "We're looking for a Product Manager to lead the development of our core products. You'll define product vision, gather requirements, and work with cross-functional teams.",
    department: "Product",
    location: "Chicago, IL",
    employmentType: "Full-time",
    experienceLevel: "Mid",
    status: "Active",
    createdAt: "2023-09-12",
    ctcRange: "$95,000 - $130,000",
    qualifications: [
      "Bachelor's degree in Business or related field",
      "3+ years of product management experience"
    ],
    responsibilities: [
      "Define product roadmap",
      "Gather and prioritize requirements",
      "Work with engineering and design",
      "Analyze market trends"
    ],
    requirements: [
      "Technical background",
      "Strong analytical skills",
      "Excellent communication",
      "Experience with Agile methodologies"
    ],
    skills: ["Product Strategy", "JIRA", "Market Research", "Agile", "User Stories"],
    benefits: [
      "Performance bonuses",
      "Leadership training",
      "Product management tools budget",
      "Team offsites"
    ]
  },
  {
    id: 6,
    jdId: 9123,
    title: "DevOps Engineer",
    description: "Join our DevOps team to build and maintain our cloud infrastructure and CI/CD pipelines. You'll help automate deployments and ensure system reliability.",
    department: "Engineering",
    location: "Remote",
    employmentType: "Contract",
    experienceLevel: "Senior",
    status: "Active",
    createdAt: "2023-10-01",
    ctcRange: "$100 - $150/hour",
    qualifications: [
      "Relevant certifications (AWS/GCP)",
      "5+ years of DevOps experience"
    ],
    responsibilities: [
      "Manage cloud infrastructure",
      "Implement CI/CD pipelines",
      "Monitor system performance",
      "Ensure security compliance"
    ],
    requirements: [
      "Expertise in Terraform/Ansible",
      "Kubernetes experience",
      "Strong scripting skills",
      "Networking knowledge"
    ],
    skills: ["AWS", "Kubernetes", "Terraform", "CI/CD", "Bash"],
    benefits: [
      "Flexible contract terms",
      "Remote work",
      "Tech equipment provided",
      "Performance bonuses"
    ]
  },
  {
    id: 7,
    jdId: 9345,
    title: "Marketing Intern",
    description: "Great opportunity for a marketing student to gain hands-on experience in digital marketing, content creation, and campaign management.",
    department: "Marketing",
    location: "Austin, TX",
    employmentType: "Internship",
    experienceLevel: "Entry",
    status: "Active",
    createdAt: "2023-11-15",
    ctcRange: "$20 - $25/hour",
    qualifications: [
      "Currently pursuing Marketing degree",
      "Basic understanding of digital marketing"
    ],
    responsibilities: [
      "Assist with social media management",
      "Help create marketing content",
      "Support campaign execution",
      "Analyze marketing metrics"
    ],
    requirements: [
      "Strong writing skills",
      "Familiarity with social platforms",
      "Eagerness to learn",
      "Basic analytics skills"
    ],
    skills: ["Social Media", "Content Creation", "SEO Basics", "Google Analytics"],
    benefits: [
      "College credit available",
      "Mentorship program",
      "Potential full-time offer",
      "Networking opportunities"
    ]
  },
  {
    id: 8,
    jdId: "AB123",
    title: "QA Engineer",
    description: "We're looking for a detail-oriented QA Engineer to ensure the quality of our software products through manual and automated testing.",
    department: "Engineering",
    location: "Seattle, WA",
    employmentType: "Full-time",
    experienceLevel: "Mid",
    status: "Inactive",
    createdAt: "2023-04-22",
    ctcRange: "$80,000 - $100,000",
    qualifications: [
      "Degree in CS or related field",
      "2+ years of QA experience"
    ],
    responsibilities: [
      "Create test plans and cases",
      "Perform manual testing",
      "Develop automated tests",
      "Report and track bugs"
    ],
    requirements: [
      "Experience with testing frameworks",
      "Basic programming skills",
      "Attention to detail",
      "Understanding of SDLC"
    ],
    skills: ["Selenium", "JIRA", "Test Automation", "Manual Testing", "Postman"],
    benefits: [
      "Health benefits",
      "Flexible PTO",
      "Professional certification support",
      "Team building events"
    ]
  },
  {
    id: 9,
    jdId: "BJ87",
    title: "Technical Writer",
    description: "Join our documentation team to create clear and comprehensive technical documentation for our products and APIs.",
    department: "Documentation",
    location: "Remote",
    employmentType: "Part-time",
    experienceLevel: "Mid",
    status: "Active",
    createdAt: "2023-12-05",
    ctcRange: "$45 - $65/hour",
    qualifications: [
      "Degree in Technical Writing or related field",
      "Portfolio of technical documentation"
    ],
    responsibilities: [
      "Write API documentation",
      "Create user guides",
      "Work with engineering teams",
      "Maintain documentation site"
    ],
    requirements: [
      "Excellent writing skills",
      "Ability to explain complex concepts",
      "Basic understanding of programming",
      "Experience with docs-as-code"
    ],
    skills: ["Technical Writing", "Markdown", "Git", "API Documentation", "Diagrams"],
    benefits: [
      "Flexible hours",
      "Remote work",
      "Professional development",
      "Annual tech budget"
    ]
  },
  {
    id: 10,
    jdId: "KJ009",
    title: "Customer Support Specialist",
    description: "Provide exceptional customer support for our SaaS product, helping users with technical issues and product questions.",
    department: "Support",
    location: "Portland, OR",
    employmentType: "Full-time",
    experienceLevel: "Entry",
    status: "Draft",
    createdAt: "2024-01-10",
    ctcRange: "$50,000 - $65,000",
    qualifications: [
      "Customer service experience",
      "Technical aptitude"
    ],
    responsibilities: [
      "Respond to customer inquiries",
      "Troubleshoot technical issues",
      "Document common solutions",
      "Escalate complex issues"
    ],
    requirements: [
      "Excellent communication skills",
      "Patience and empathy",
      "Basic technical knowledge",
      "Ability to learn quickly"
    ],
    skills: ["Customer Service", "Zendesk", "Troubleshooting", "Product Knowledge"],
    benefits: [
      "Health insurance",
      "Career growth opportunities",
      "Quarterly bonuses",
      "Team outings"
    ]
  }
];

export const companies = [
  { id: 1, name: "Tech Corp Inc.", industry: "Information Technology", contactEmail: "hr@techcorp.com", phone: "+1 (555) 123-4567", address: "123 Tech Street, Silicon Valley, CA" },
  { id: 2, name: "Biz Solutions", industry: "Finance", contactEmail: "contact@bizsolutions.com", phone: "+1 (555) 234-5678", address: "456 Biz Ave, New York, NY" },
  { id: 3, name: "Green Energy", industry: "Energy", contactEmail: "info@greenenergy.com", phone: "+1 (555) 345-6789", address: "789 Green Blvd, Austin, TX" },
  { id: 4, name: "Health Plus", industry: "Healthcare", contactEmail: "careers@healthplus.com", phone: "+1 (555) 456-7890", address: "101 Medical Ln, Denver, CO" },
  { id: 5, name: "EduSmart", industry: "Education", contactEmail: "jobs@edusmart.com", phone: "+1 (555) 567-8901", address: "121 School Rd, Boston, MA" },
  { id: 6, name: "RetailerX", industry: "Retail", contactEmail: "careers@retailerx.com", phone: "+1 (555) 678-9012", address: "202 Market St, Seattle, WA" },
  { id: 7, name: "LogiTrack", industry: "Logistics", contactEmail: "jobs@logitrack.com", phone: "+1 (555) 789-0123", address: "303 Transport Dr, Chicago, IL" },
  { id: 8, name: "Creative Labs", industry: "Design", contactEmail: "join@creativelabs.com", phone: "+1 (555) 890-1234", address: "404 Art St, Portland, OR" },
  { id: 9, name: "SecureNet", industry: "Cybersecurity", contactEmail: "hr@securenet.com", phone: "+1 (555) 901-2345", address: "505 Safety Ln, Washington, DC" },
  { id: 10, name: "AgroWorld", industry: "Agriculture", contactEmail: "jobs@agroworld.com", phone: "+1 (555) 012-3456", address: "606 Farm Way, Omaha, NE" },
];

export const candidates = [
  { id: 1, name: "Alice Smith", email: "alice.smith@example.com", phone: "1234567890", appliedFor: "Senior Software Developer", company: "Tech Corp Inc.", status: "In-Review", assignedTo: "Jane Doe", interviewDate: "2023-06-15" },
  { id: 2, name: "Michael Brown", email: "michael.brown@example.com", phone: "2345678901", appliedFor: "QA Tester", company: "Biz Solutions", status: "Interview Scheduled", assignedTo: "John Doe", interviewDate: "2023-06-18" },
  { id: 3, name: "Emma Wilson", email: "emma.wilson@example.com", phone: "3456789012", appliedFor: "HR Executive", company: "Green Energy", status: "Selected", assignedTo: "Emily Davis", interviewDate: "2023-06-20" },
  { id: 4, name: "Liam Johnson", email: "liam.johnson@example.com", phone: "4567890123", appliedFor: "UI/UX Designer", company: "Creative Labs", status: "In-Review", assignedTo: "Laura Johnson", interviewDate: "2023-06-22" },
  { id: 5, name: "Noah Davis", email: "noah.davis@example.com", phone: "5678901234", appliedFor: "Finance Analyst", company: "RetailerX", status: "Rejected", assignedTo: "David Wilson", interviewDate: "2023-06-25" },
  { id: 6, name: "Ava Moore", email: "ava.moore@example.com", phone: "6789012345", appliedFor: "Intern Developer", company: "Tech Corp Inc.", status: "Hired", assignedTo: "Robert Brown", interviewDate: "2023-06-28" },
  { id: 7, name: "Lucas Taylor", email: "lucas.taylor@example.com", phone: "7890123456", appliedFor: "Business Analyst", company: "Biz Solutions", status: "In-Review", assignedTo: "Sophia Lee", interviewDate: "2023-06-30" },
  { id: 8, name: "Isabella Anderson", email: "isabella.anderson@example.com", phone: "8901234567", appliedFor: "DevOps Engineer", company: "SecureNet", status: "Interview Scheduled", assignedTo: "Brian Taylor", interviewDate: "2023-07-02" },
  { id: 9, name: "Mason Martinez", email: "mason.martinez@example.com", phone: "9012345678", appliedFor: "Tech Lead", company: "Health Plus", status: "In-Review", assignedTo: "Jane Smith", interviewDate: "2023-07-05" },
  { id: 10, name: "Mia Thomas", email: "mia.thomas@example.com", phone: "0123456789", appliedFor: "Content Writer", company: "EduSmart", status: "Interview Scheduled", assignedTo: "Emily Davis", interviewDate: "2023-07-08" },
];

export const incentives = [
  { id: 1, candidateId: 1, employeeId: 2, amount: 5000, status: "Pending", joinDate: "2023-06-01", confirmationDate: null },
  { id: 2, candidateId: 2, employeeId: 1, amount: 4500, status: "Confirmed", joinDate: "2023-06-03", confirmationDate: "2023-06-10" },
  { id: 3, candidateId: 3, employeeId: 3, amount: 3000, status: "Pending", joinDate: "2023-06-05", confirmationDate: null },
  { id: 4, candidateId: 4, employeeId: 4, amount: 3200, status: "Confirmed", joinDate: "2023-06-07", confirmationDate: "2023-06-14" },
  { id: 5, candidateId: 5, employeeId: 5, amount: 2000, status: "Rejected", joinDate: "2023-06-09", confirmationDate: null },
  { id: 6, candidateId: 6, employeeId: 6, amount: 1000, status: "Confirmed", joinDate: "2023-06-11", confirmationDate: "2023-06-18" },
  { id: 7, candidateId: 7, employeeId: 7, amount: 3500, status: "Pending", joinDate: "2023-06-13", confirmationDate: null },
  { id: 8, candidateId: 8, employeeId: 8, amount: 4000, status: "Confirmed", joinDate: "2023-06-15", confirmationDate: "2023-06-22" },
  { id: 9, candidateId: 9, employeeId: 9, amount: 6000, status: "Confirmed", joinDate: "2023-06-17", confirmationDate: "2023-06-24" },
  { id: 10, candidateId: 10, employeeId: 10, amount: 2500, status: "Pending", joinDate: "2023-06-19", confirmationDate: null },
];
