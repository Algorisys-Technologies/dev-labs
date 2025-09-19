import { useState } from 'react';
import { jdEntries } from "~/utils/dummyData";
import { Link } from "@remix-run/react";

type JDEntry = {
  id: string | number;
  title: string;
  description: string;
  department: string;
  location: string;
  employmentType: "Full-time" | "Part-time" | "Contract" | "Internship";
  experienceLevel: "Entry" | "Mid" | "Senior" | "Lead";
  status: "Active" | "Inactive" | "Draft";
  createdAt: string;
  ctcRange: string;
  qualifications: string[];
  responsibilities: string[];
  requirements: string[];
  skills: string[];
  benefits: string[];
  jdId: string[];
};

export default function JDMaster() {
  // View Modal State
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [selectedJD, setSelectedJD] = useState<JDEntry | null>(null);

  // Add JD Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newJD, setNewJD] = useState<Partial<JDEntry>>({
    title: '',
    description: '',
    department: '',
    location: '',
    employmentType: 'Full-time',
    experienceLevel: 'Mid',
    status: 'Draft',
    createdAt: new Date().toISOString().split('T')[0],
    ctcRange: '',
    qualifications: [],
    responsibilities: [],
    requirements: [],
    skills: [],
    benefits: []
  });

  // Open/Close View Modal
  const openViewModal = (jd: JDEntry) => {
    setSelectedJD(jd);
    setIsViewModalOpen(true);
  };

  const closeViewModal = () => {
    setIsViewModalOpen(false);
    setSelectedJD(null);
  };

  // Open/Close Add Modal
  const openAddModal = () => {
    setIsAddModalOpen(true);
  };

  const closeAddModal = () => {
    setIsAddModalOpen(false);
    setNewJD({
      title: '',
      description: '',
      department: '',
      location: '',
      employmentType: 'Full-time',
      experienceLevel: 'Mid',
      status: 'Draft',
      createdAt: new Date().toISOString().split('T')[0],
      ctcRange: '',
      qualifications: [],
      responsibilities: [],
      requirements: [],
      skills: [],
      benefits: []
    });
  };

  // Handle form input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setNewJD(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  // Handle array field changes
  const handleArrayFieldChange = (field: string, index: number, value: string) => {
    setNewJD(prev => {
      const updatedArray = [...(prev[field as keyof JDEntry] || []) as string[]];
      updatedArray[index] = value;
      return {
        ...prev,
        [field]: updatedArray
      };
    });
  };

  // Add new item to array field
  const addArrayFieldItem = (field: string) => {
    setNewJD(prev => ({
      ...prev,
      [field]: [...(prev[field as keyof JDEntry] || []), '']
    }));
  };

  // Remove item from array field
  const removeArrayFieldItem = (field: string, index: number) => {
    setNewJD(prev => {
      const updatedArray = [...(prev[field as keyof JDEntry] || []) as string[]];
      updatedArray.splice(index, 1);
      return {
        ...prev,
        [field]: updatedArray
      };
    });
  };

  // Handle form submission
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('New JD:', newJD);
    closeAddModal();
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">JD Master</h1>
        <button
          onClick={openAddModal}
          className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
        >
          Add New JD
        </button>
      </div>

      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                JD ID
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Department
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Location
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Type
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" className="relative px-6 py-3">
                <span className="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {jdEntries.map((jd) => (
              <tr key={jd.id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">{jd.jdId}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">
                    {jd.title}
                    <div className="text-xs text-gray-500">{jd.experienceLevel} Level</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">{jd.department}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">{jd.location}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">{jd.employmentType}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span
                    className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${jd.status === "Active"
                        ? "bg-green-100 text-green-800"
                        : jd.status === "Inactive"
                          ? "bg-gray-100 text-gray-800"
                          : "bg-yellow-100 text-yellow-800"
                      }`}
                  >
                    {jd.status}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    onClick={() => openViewModal(jd)}
                    className="text-indigo-600 hover:text-indigo-900 mr-3"
                  >
                    View
                  </button>
                  <Link
                    to={``}
                    className="text-indigo-600 hover:text-indigo-900"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* View JD Modal */}
      {isViewModalOpen && selectedJD && (
        <div className="fixed z-10 inset-0 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 transition-opacity" aria-hidden="true">
              <div className="absolute inset-0 bg-gray-500 opacity-75" onClick={closeViewModal}></div>
            </div>
            <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="sm:flex sm:items-start">
                  <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="text-2xl leading-6 font-bold text-gray-900">
                          {selectedJD.title}
                        </h3>
                        <p className="mt-1 text-sm text-gray-500">
                          {selectedJD.department} • {selectedJD.location} • {selectedJD.experienceLevel} Level
                        </p>
                      </div>
                      <div className="text-right">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${selectedJD.status === "Active"
                            ? "bg-green-100 text-green-800"
                            : selectedJD.status === "Inactive"
                              ? "bg-gray-100 text-gray-800"
                              : "bg-yellow-100 text-yellow-800"
                          }`}>
                          {selectedJD.status}
                        </span>
                        <p className="mt-1 text-xs text-gray-500">Created: {selectedJD.createdAt}</p>
                      </div>
                    </div>

                    <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="bg-gray-50 p-4 rounded-lg">
                        <h4 className="text-lg font-medium text-gray-900 mb-2">Job Details</h4>
                        <div className="space-y-3">
                          <div>
                            <p className="text-sm font-medium text-gray-500">Employment Type</p>
                            <p className="mt-1 text-sm text-gray-900">{selectedJD.employmentType}</p>
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-500">Experience Level</p>
                            <p className="mt-1 text-sm text-gray-900">{selectedJD.experienceLevel}</p>
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-500">Compensation</p>
                            <p className="mt-1 text-sm text-gray-900">{selectedJD.ctcRange || 'Not specified'}</p>
                          </div>
                        </div>
                      </div>

                      <div className="bg-gray-50 p-4 rounded-lg">
                        <h4 className="text-lg font-medium text-gray-900 mb-2">Qualifications</h4>
                        {selectedJD.qualifications && selectedJD.qualifications.length > 0 ? (
                          <ul className="mt-1 text-sm text-gray-900 list-disc list-inside space-y-1">
                            {selectedJD.qualifications.map((item, index) => (
                              <li key={index}>{item}</li>
                            ))}
                          </ul>
                        ) : (
                          <p className="text-sm text-gray-500">No qualifications specified</p>
                        )}
                      </div>
                    </div>

                    <div className="mt-4">
                      <h4 className="text-lg font-medium text-gray-900 mb-2">Job Description</h4>
                      <p className="mt-1 text-sm text-gray-900 whitespace-pre-line">{selectedJD.description}</p>
                    </div>

                    {selectedJD.responsibilities && selectedJD.responsibilities.length > 0 && (
                      <div className="mt-4">
                        <h4 className="text-lg font-medium text-gray-900 mb-2">Key Responsibilities</h4>
                        <ul className="mt-1 text-sm text-gray-900 list-disc list-inside space-y-1">
                          {selectedJD.responsibilities.map((item, index) => (
                            <li key={index}>{item}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                      {selectedJD.requirements && selectedJD.requirements.length > 0 && (
                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-2">Requirements</h4>
                          <ul className="mt-1 text-sm text-gray-900 list-disc list-inside space-y-1">
                            {selectedJD.requirements.map((item, index) => (
                              <li key={index}>{item}</li>
                            ))}
                          </ul>
                        </div>
                      )}

                      {selectedJD.skills && selectedJD.skills.length > 0 && (
                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-2">Skills</h4>
                          <div className="mt-1 flex flex-wrap gap-2">
                            {selectedJD.skills.map((skill, index) => (
                              <span key={index} className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                {skill}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>

                    {selectedJD.benefits && selectedJD.benefits.length > 0 && (
                      <div className="mt-4">
                        <h4 className="text-lg font-medium text-gray-900 mb-2">Benefits</h4>
                        <ul className="mt-1 text-sm text-gray-900 list-disc list-inside space-y-1">
                          {selectedJD.benefits.map((item, index) => (
                            <li key={index}>{item}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button
                  type="button"
                  className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                  onClick={closeViewModal}
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add JD Modal */}
      {isAddModalOpen && (
        <div className="fixed z-10 inset-0 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 transition-opacity" aria-hidden="true">
              <div className="absolute inset-0 bg-gray-500 opacity-75" onClick={closeAddModal}></div>
            </div>
            <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
              <form onSubmit={handleSubmit}>
                <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                  <div className="sm:flex sm:items-start">
                    <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                      <h3 className="text-lg leading-6 font-medium text-gray-900">
                        Add New Job Description
                      </h3>
                      <div className="mt-4 space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                              Job Title*
                            </label>
                            <input
                              type="text"
                              name="title"
                              id="title"
                              value={newJD.title}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            />
                          </div>

                          <div>
                            <label htmlFor="department" className="block text-sm font-medium text-gray-700">
                              Department*
                            </label>
                            <input
                              type="text"
                              name="department"
                              id="department"
                              value={newJD.department}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div>
                            <label htmlFor="location" className="block text-sm font-medium text-gray-700">
                              Location*
                            </label>
                            <input
                              type="text"
                              name="location"
                              id="location"
                              value={newJD.location}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            />
                          </div>

                          <div>
                            <label htmlFor="employmentType" className="block text-sm font-medium text-gray-700">
                              Employment Type*
                            </label>
                            <select
                              name="employmentType"
                              id="employmentType"
                              value={newJD.employmentType}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            >
                              <option value="Full-time">Full-time</option>
                              <option value="Part-time">Part-time</option>
                              <option value="Contract">Contract</option>
                              <option value="Internship">Internship</option>
                            </select>
                          </div>

                          <div>
                            <label htmlFor="experienceLevel" className="block text-sm font-medium text-gray-700">
                              Experience Level*
                            </label>
                            <select
                              name="experienceLevel"
                              id="experienceLevel"
                              value={newJD.experienceLevel}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            >
                              <option value="Entry">Entry Level</option>
                              <option value="Mid">Mid Level</option>
                              <option value="Senior">Senior Level</option>
                              <option value="Lead">Lead</option>
                            </select>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <label htmlFor="status" className="block text-sm font-medium text-gray-700">
                              Status*
                            </label>
                            <select
                              name="status"
                              id="status"
                              value={newJD.status}
                              onChange={handleInputChange}
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              required
                            >
                              <option value="Draft">Draft</option>
                              <option value="Active">Active</option>
                              <option value="Inactive">Inactive</option>
                            </select>
                          </div>

                          <div>
                            <label htmlFor="ctcRange" className="block text-sm font-medium text-gray-700">
                              CTC Range
                            </label>
                            <input
                              type="text"
                              name="ctcRange"
                              id="ctcRange"
                              value={newJD.ctcRange}
                              onChange={handleInputChange}
                              placeholder="e.g. $80,000 - $100,000"
                              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            />
                          </div>
                        </div>

                        <div>
                          <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                            Job Description*
                          </label>
                          <textarea
                            name="description"
                            id="description"
                            rows={4}
                            value={newJD.description}
                            onChange={handleInputChange}
                            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            required
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Key Responsibilities*
                          </label>
                          {newJD.responsibilities?.map((item, index) => (
                            <div key={index} className="mt-2 flex items-center">
                              <input
                                type="text"
                                value={item}
                                onChange={(e) => handleArrayFieldChange('responsibilities', index, e.target.value)}
                                className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                required
                              />
                              <button
                                type="button"
                                onClick={() => removeArrayFieldItem('responsibilities', index)}
                                className="ml-2 inline-flex items-center p-1 border border-transparent text-sm leading-4 font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                              </button>
                            </div>
                          ))}
                          <button
                            type="button"
                            onClick={() => addArrayFieldItem('responsibilities')}
                            className="mt-2 inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                            </svg>
                            Add Responsibility
                          </button>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Requirements*
                          </label>
                          {newJD.requirements?.map((item, index) => (
                            <div key={index} className="mt-2 flex items-center">
                              <input
                                type="text"
                                value={item}
                                onChange={(e) => handleArrayFieldChange('requirements', index, e.target.value)}
                                className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                required
                              />
                              <button
                                type="button"
                                onClick={() => removeArrayFieldItem('requirements', index)}
                                className="ml-2 inline-flex items-center p-1 border border-transparent text-sm leading-4 font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                              </button>
                            </div>
                          ))}
                          <button
                            type="button"
                            onClick={() => addArrayFieldItem('requirements')}
                            className="mt-2 inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                            </svg>
                            Add Requirement
                          </button>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Required Qualifications*
                          </label>
                          {newJD.qualifications?.map((item, index) => (
                            <div key={index} className="mt-2 flex items-center">
                              <input
                                type="text"
                                value={item}
                                onChange={(e) => handleArrayFieldChange('qualifications', index, e.target.value)}
                                className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                required
                              />
                              <button
                                type="button"
                                onClick={() => removeArrayFieldItem('qualifications', index)}
                                className="ml-2 inline-flex items-center p-1 border border-transparent text-sm leading-4 font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                              </button>
                            </div>
                          ))}
                          <button
                            type="button"
                            onClick={() => addArrayFieldItem('qualifications')}
                            className="mt-2 inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                            </svg>
                            Add Qualification
                          </button>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Skills
                          </label>
                          {newJD.skills?.map((item, index) => (
                            <div key={index} className="mt-2 flex items-center">
                              <input
                                type="text"
                                value={item}
                                onChange={(e) => handleArrayFieldChange('skills', index, e.target.value)}
                                className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              />
                              <button
                                type="button"
                                onClick={() => removeArrayFieldItem('skills', index)}
                                className="ml-2 inline-flex items-center p-1 border border-transparent text-sm leading-4 font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                              </button>
                            </div>
                          ))}
                          <button
                            type="button"
                            onClick={() => addArrayFieldItem('skills')}
                            className="mt-2 inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                            </svg>
                            Add Skill
                          </button>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Benefits
                          </label>
                          {newJD.benefits?.map((item, index) => (
                            <div key={index} className="mt-2 flex items-center">
                              <input
                                type="text"
                                value={item}
                                onChange={(e) => handleArrayFieldChange('benefits', index, e.target.value)}
                                className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                              />
                              <button
                                type="button"
                                onClick={() => removeArrayFieldItem('benefits', index)}
                                className="ml-2 inline-flex items-center p-1 border border-transparent text-sm leading-4 font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                              </button>
                            </div>
                          ))}
                          <button
                            type="button"
                            onClick={() => addArrayFieldItem('benefits')}
                            className="mt-2 inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                            </svg>
                            Add Benefit
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                  <button
                    type="submit"
                    className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm"
                  >
                    Save JD
                  </button>
                  <button
                    type="button"
                    className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                    onClick={closeAddModal}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}