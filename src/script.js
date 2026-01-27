class TaskManager {
    constructor() {
        this.tasks = JSON.parse(localStorage.getItem('devops-tasks')) || [];
        this.currentFilter = 'all';
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.loadTasks();
        this.updateStats();
        this.updateBuildInfo();
    }
    
    bindEvents() {
        // Add task
        document.getElementById('addTaskBtn').addEventListener('click', () => this.addTask());
        document.getElementById('taskInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addTask();
        });
        
        // Filters
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.setFilter(e.target.dataset.filter));
        });
        
        // Actions
        document.getElementById('clearCompleted').addEventListener('click', () => this.clearCompleted());
        document.getElementById('exportTasks').addEventListener('click', () => this.exportTasks());
    }
    
    addTask() {
        const input = document.getElementById('taskInput');
        const text = input.value.trim();
        const priority = document.getElementById('prioritySelect').value;
        const dueDate = document.getElementById('dueDate').value;
        
        if (!text) {
            this.showNotification('Please enter a task description', 'warning');
            input.focus();
            return;
        }
        
        const task = {
            id: Date.now(),
            text: text,
            priority: priority,
            dueDate: dueDate || null,
            completed: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        this.tasks.unshift(task);
        this.saveTasks();
        this.loadTasks();
        this.updateStats();
        
        input.value = '';
        input.focus();
        document.getElementById('dueDate').value = '';
        
        this.showNotification('Task added successfully!', 'success');
    }
    
    deleteTask(id) {
        this.tasks = this.tasks.filter(task => task.id !== id);
        this.saveTasks();
        this.loadTasks();
        this.updateStats();
        this.showNotification('Task deleted', 'info');
    }
    
    toggleComplete(id) {
        this.tasks = this.tasks.map(task => {
            if (task.id === id) {
                return {
                    ...task,
                    completed: !task.completed,
                    updatedAt: new Date().toISOString()
                };
            }
            return task;
        });
        
        this.saveTasks();
        this.loadTasks();
        this.updateStats();
    }
    
    editTask(id, newText) {
        if (!newText.trim()) return;
        
        this.tasks = this.tasks.map(task => {
            if (task.id === id) {
                return {
                    ...task,
                    text: newText.trim(),
                    updatedAt: new Date().toISOString()
                };
            }
            return task;
        });
        
        this.saveTasks();
        this.loadTasks();
        this.showNotification('Task updated', 'success');
    }
    
    setFilter(filter) {
        this.currentFilter = filter;
        
        // Update active button
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.filter === filter) {
                btn.classList.add('active');
            }
        });
        
        this.loadTasks();
    }
    
    clearCompleted() {
        this.tasks = this.tasks.filter(task => !task.completed);
        this.saveTasks();
        this.loadTasks();
        this.updateStats();
        this.showNotification('Completed tasks cleared', 'info');
    }
    
    exportTasks() {
        const data = {
            tasks: this.tasks,
            exportedAt: new Date().toISOString(),
            total: this.tasks.length,
            completed: this.tasks.filter(t => t.completed).length
        };
        
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `tasks-export-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.showNotification('Tasks exported successfully', 'success');
    }
    
    loadTasks() {
        const taskList = document.getElementById('taskList');
        const emptyState = document.getElementById('emptyState');
        
        // Filter tasks
        let filteredTasks;
        switch(this.currentFilter) {
            case 'active':
                filteredTasks = this.tasks.filter(task => !task.completed);
                break;
            case 'completed':
                filteredTasks = this.tasks.filter(task => task.completed);
                break;
            default:
                filteredTasks = this.tasks;
        }
        
        // Clear list
        taskList.innerHTML = '';
        
        // Show/hide empty state
        if (filteredTasks.length === 0) {
            emptyState.style.display = 'block';
        } else {
            emptyState.style.display = 'none';
            
            // Render tasks
            filteredTasks.forEach(task => {
                const taskEl = this.createTaskElement(task);
                taskList.appendChild(taskEl);
            });
        }
    }
    
    createTaskElement(task) {
        const li = document.createElement('li');
        li.className = `task-item ${task.priority} ${task.completed ? 'completed' : ''}`;
        li.dataset.id = task.id;
        
        // Format date
        let dueDateDisplay = '';
        if (task.dueDate) {
            const dueDate = new Date(task.dueDate);
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            
            if (dueDate < today && !task.completed) {
                dueDateDisplay = `<span class="due-date" style="color: var(--danger-color);">
                    <i class="fas fa-exclamation-circle"></i> Overdue: ${dueDate.toLocaleDateString()}
                </span>`;
            } else {
                dueDateDisplay = `<span class="due-date">
                    <i class="fas fa-calendar-alt"></i> ${dueDate.toLocaleDateString()}
                </span>`;
            }
        }
        
        li.innerHTML = `
            <div class="task-content">
                <input type="checkbox" class="task-checkbox" ${task.completed ? 'checked' : ''}>
                <span class="task-text">${this.escapeHtml(task.text)}</span>
            </div>
            <div class="task-meta">
                <span class="task-priority priority-${task.priority}">
                    ${task.priority.charAt(0).toUpperCase() + task.priority.slice(1)}
                </span>
                ${dueDateDisplay}
            </div>
            <div class="task-actions">
                <button class="edit-btn" title="Edit task">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="delete-btn" title="Delete task">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
        
        // Add event listeners
        const checkbox = li.querySelector('.task-checkbox');
        const deleteBtn = li.querySelector('.delete-btn');
        const editBtn = li.querySelector('.edit-btn');
        const taskText = li.querySelector('.task-text');
        
        checkbox.addEventListener('change', () => this.toggleComplete(task.id));
        deleteBtn.addEventListener('click', () => this.deleteTask(task.id));
        
        // Edit functionality
        editBtn.addEventListener('click', () => this.enableEdit(taskText, task.id));
        taskText.addEventListener('dblclick', () => this.enableEdit(taskText, task.id));
        
        return li;
    }
    
    enableEdit(element, taskId) {
        const currentText = element.textContent;
        const input = document.createElement('input');
        input.type = 'text';
        input.value = currentText;
        input.className = 'edit-input';
        input.style.cssText = `
            width: 100%;
            padding: 5px;
            border: 2px solid var(--primary-color);
            border-radius: 4px;
            font-size: 1.1rem;
        `;
        
        element.replaceWith(input);
        input.focus();
        input.select();
        
        const saveEdit = () => {
            this.editTask(taskId, input.value);
        };
        
        input.addEventListener('blur', saveEdit);
        input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') saveEdit();
        });
    }
    
    updateStats() {
        const total = this.tasks.length;
        const completed = this.tasks.filter(task => task.completed).length;
        const pending = total - completed;
        
        document.getElementById('totalTasks').textContent = total;
        document.getElementById('completedTasks').textContent = completed;
        document.getElementById('pendingTasks').textContent = pending;
    }
    
    updateBuildInfo() {
        // Simulate build info from CI/CD
        const buildInfo = {
            version: 'v1.0.0',
            buildDate: new Date().toISOString().split('T')[0],
            pipeline: 'GitHub Actions',
            status: 'Success'
        };
        
        document.getElementById('buildVersion').textContent = 
            `Build: ${buildInfo.version} | ${buildInfo.buildDate}`;
    }
    
    saveTasks() {
        localStorage.setItem('devops-tasks', JSON.stringify(this.tasks));
    }
    
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <i class="fas fa-${this.getNotificationIcon(type)}"></i>
            <span>${message}</span>
            <button class="notification-close"><i class="fas fa-times"></i></button>
        `;
        
        // Add styles
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${this.getNotificationColor(type)};
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 1000;
            animation: slideIn 0.3s ease;
        `;
        
        document.body.appendChild(notification);
        
        // Add close button event
        notification.querySelector('.notification-close').addEventListener('click', () => {
            notification.remove();
        });
        
        // Auto remove after 3 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 3000);
    }
    
    getNotificationIcon(type) {
        const icons = {
            success: 'check-circle',
            warning: 'exclamation-triangle',
            error: 'times-circle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }
    
    getNotificationColor(type) {
        const colors = {
            success: '#10b981',
            warning: '#f59e0b',
            error: '#ef4444',
            info: '#3b82f6'
        };
        return colors[type] || '#3b82f6';
    }
    
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
    window.taskManager = new TaskManager();
    
    // Add animation styles
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        .notification-close {
            background: none;
            border: none;
            color: white;
            cursor: pointer;
            padding: 0;
            margin-left: 10px;
        }
        
        .edit-input {
            width: 100%;
            padding: 5px;
            border: 2px solid var(--primary-color);
            border-radius: 4px;
            font-size: 1.1rem;
        }
    `;
    document.head.appendChild(style);
});
