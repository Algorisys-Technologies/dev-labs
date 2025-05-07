import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, FlatList, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import axios from 'axios';
import Modal from 'react-native-modal';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

const API_URL = 'http://192.168.1.14:8080/todos'; // Use your actual IP for mobile

export default function App() {
  const [todos, setTodos] = useState([]);
  const [isModalVisible, setModalVisible] = useState(false);
  const [currentTodo, setCurrentTodo] = useState(null);
  const [formData, setFormData] = useState({ title: '', description: '' });

  useEffect(() => {
    fetchTodos();
  }, []);

  const fetchTodos = async () => {
    try {
      const response = await axios.get(API_URL);
      console.log("res", response.data);
      setTodos(response.data);
    } catch (error) {
      Alert.alert('Error', 'Failed to fetch todos');
      console.log(error, "hjdwih")
    }
  };

  const handleSubmit = async () => {
    if (!formData.title) return;

    try {
      if (currentTodo) {
        await axios.put(`${API_URL}/${currentTodo.id}`, {
          ...formData,
          completed: currentTodo.completed
        });
      } else {
        await axios.post(API_URL, formData);
      }
      fetchTodos();
      setModalVisible(false);
      setFormData({ title: '', description: '' });
    } catch (error) {
      Alert.alert('Error', 'Operation failed');
    }
  };

  const deleteTodo = async (id) => {
    try {
      await axios.delete(`${API_URL}/${id}`);
      fetchTodos();
    } catch (error) {
      Alert.alert('Error', 'Failed to delete todo');
    }
  };

  const toggleComplete = async (todo) => {
    try {
      await axios.put(`${API_URL}/${todo.id}`, {
        ...todo,
        completed: !todo.completed
      });
      fetchTodos();
    } catch (error) {
      Alert.alert('Error', 'Update failed');
    }
  };

  const openEditModal = (todo) => {
    setCurrentTodo(todo);
    setFormData({
      title: todo.title,
      description: todo.description || ''
    });
    setModalVisible(true);
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView edges={['top']} style={{ flex: 1 }}>
        <View style={styles.container}>
          {/* Add Heading */}
          <View style={styles.headerContainer}>
            <Text style={styles.header}>My Todo App</Text>
            <Text style={styles.subHeader}>Manage your tasks</Text>
          </View>
          <Button
            title="Add New Todo"
            onPress={() => {
              setCurrentTodo(null);
              setFormData({ title: '', description: '' });
              setModalVisible(true);
            }}
          />

          <FlatList
            data={todos}
            keyExtractor={(item) => item.id.toString()}
            renderItem={({ item }) => (
              <View style={styles.todoItem}>
                <TouchableOpacity onPress={() => toggleComplete(item)}>
                  <Text style={[styles.checkbox, item.completed && styles.completed]}>
                    {item.completed ? '✓' : '○'}
                  </Text>
                </TouchableOpacity>

                <View style={styles.todoContent}>
                  <Text style={[styles.title, item.completed && styles.completedText]}>
                    {item.title}
                  </Text>
                  {item.description && <Text style={styles.description}>{item.description}</Text>}
                </View>

                <View style={styles.actions}>
                  <Button title="Edit" onPress={() => openEditModal(item)} />
                  <Button title="Delete" color="red" onPress={() => deleteTodo(item.id)} />
                </View>
              </View>
            )}
          />

          <Modal isVisible={isModalVisible}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>
                {currentTodo ? 'Edit Todo' : 'New Todo'}
              </Text>

              <TextInput
                style={styles.input}
                placeholder="Title"
                value={formData.title}
                onChangeText={(text) => setFormData({ ...formData, title: text })}
              />

              <TextInput
                style={[styles.input, styles.multilineInput]}
                placeholder="Description"
                multiline
                value={formData.description}
                onChangeText={(text) => setFormData({ ...formData, description: text })}
              />

              <View style={styles.modalButtons}>
                <Button
                  title="Cancel"
                  color="gray"
                  onPress={() => {
                    setModalVisible(false);
                    setCurrentTodo(null); 
                    setFormData({ title: '', description: '' });
                  }}
                />
                <Button title="Save" onPress={handleSubmit} />
              </View>
            </View>
          </Modal>
        </View>
      </SafeAreaView>
    </SafeAreaProvider >
  );
}

const styles = StyleSheet.create({
  headerContainer: {
    backgroundColor: '#3498db',
    padding: 20,
    width: '100%',
    marginBottom: 20,
    borderBottomLeftRadius: 15,
    borderBottomRightRadius: 15,
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center',
  },
  subHeader: {
    fontSize: 14,
    color: '#ecf0f1',
    textAlign: 'center',
    marginTop: 5,
  },
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#fff',
  },
  todoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
    marginBottom: 10,
    backgroundColor: '#f8f8f8',
    borderRadius: 8,
  },
  checkbox: {
    fontSize: 24,
    marginRight: 15,
  },
  completed: {
    color: 'green',
  },
  todoContent: {
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '500',
  },
  description: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  completedText: {
    textDecorationLine: 'line-through',
    color: '#888',
  },
  actions: {
    flexDirection: 'row',
    gap: 10,
  },
  modalContent: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 10,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 10,
    marginBottom: 15,
    borderRadius: 5,
  },
  multilineInput: {
    height: 80,
    textAlignVertical: 'top',
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
  },
});