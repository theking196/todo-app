# Simple Todo App - Python Flask
# Super easy to run!

from flask import Flask, render_template_string, request, jsonify
import json
import os

app = Flask(__name__)
TASKS_FILE = 'tasks.json'

# Load tasks
def load_tasks():
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, 'r') as f:
            return json.load(f)
    return []

# Save tasks
def save_tasks(tasks):
    with open(TASKS_FILE, 'w') as f:
        json.dump(tasks, f)

# HTML Template
HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>My Tasks</title>
    <style>
        body { font-family: -apple-system, sans-serif; background: #f5f5f5; margin: 0; }
        .header { background: #6200ee; color: white; padding: 20px; }
        .header h1 { margin: 0; font-size: 24px; }
        .header p { margin: 5px 0 0; opacity: 0.8; }
        .input-box { background: white; padding: 16px; display: flex; gap: 10px; }
        input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px; }
        button { background: #6200ee; color: white; border: none; padding: 12px 20px; border-radius: 8px; font-weight: bold; }
        .list { padding: 16px; }
        .task { background: white; padding: 16px; border-radius: 8px; margin-bottom: 8px; display: flex; align-items: center; }
        .task.completed span { text-decoration: line-through; color: #999; }
        .checkbox { width: 24px; height: 24px; border: 2px solid #ccc; border-radius: 50%; margin-right: 12px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
        .completed .checkbox { background: #4caf50; border-color: #4caf50; }
        .completed .checkbox::after { content: "✓"; color: white; }
        .delete { color: #ff4444; margin-left: auto; cursor: pointer; padding: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>My Tasks</h1>
        <p><span id="pending">0</span> pending, <span id="done">0</span> done</p>
    </div>
    <div class="input-box">
        <input type="text" id="input" placeholder="What needs to be done?" onkeypress="if(event.key==='Enter')addTask()">
        <button onclick="addTask()">Add</button>
    </div>
    <div class="list" id="list"></div>
    <script>
        function load() {
            fetch('/api/tasks').then(r=>r.json()).then(data => {
                const pending = data.filter(t=>!t.completed).length;
                const done = data.filter(t=>t.completed).length;
                document.getElementById('pending').textContent = pending;
                document.getElementById('done').textContent = done;
                document.getElementById('list').innerHTML = data.map(t => 
                    '<div class="task '+(t.completed?'completed':'')+'">' +
                    '<div class="checkbox" onclick="toggle('+t.id+')"></div>' +
                    '<span onclick="toggle('+t.id+')">'+t.title+'</span>' +
                    '<span class="delete" onclick="delete('+t.id+')">✕</span></div>'
                ).join('') || '<p style="text-align:center;color:#999;padding:40px">No tasks yet!</p>';
            });
        }
        function addTask() {
            const title = document.getElementById('input').value.trim();
            if(!title) return;
            fetch('/api/tasks', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({title})})
                .then(() => { document.getElementById('input').value=''; load(); });
        }
        function toggle(id) { fetch('/api/tasks/'+id, {method:'PUT'}).then(load); }
        function delete(id) { if(confirm('Delete?')) fetch('/api/tasks/'+id, {method:'DELETE'}).then(load); }
        load();
    </script>
</body>
</html>
'''

@app.route('/')
def home():
    return render_template_string(HTML)

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    return jsonify(load_tasks())

@app.route('/api/tasks', methods=['POST'])
def add_task():
    tasks = load_tasks()
    new_task = {'id': len(tasks)+1, 'title': request.json['title'], 'completed': False}
    tasks.append(new_task)
    save_tasks(tasks)
    return jsonify(new_task)

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def toggle_task():
    tasks = load_tasks()
    for t in tasks:
        if t['id'] == task_id:
            t['completed'] = not t['completed']
    save_tasks(tasks)
    return jsonify({'ok': True})

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task():
    tasks = [t for t in load_tasks() if t['id'] != task_id]
    save_tasks(tasks)
    return jsonify({'ok': True})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)