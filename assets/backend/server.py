from flask import Flask, request, jsonify
import sqlite3
import hashlib
import os
import time

app = Flask(__name__)

# ========== 创建上传文件夹 ==========
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


# ========== 数据库初始化 ==========
def init_db():
    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            nickname TEXT
        )
    ''')
    pwd = hashlib.md5('123456'.encode()).hexdigest()
    try:
        cursor.execute(
            'INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)',
            ('admin', pwd, '管理员')
        )
    except sqlite3.IntegrityError:
        pass

    pwd2 = hashlib.md5('abc123'.encode()).hexdigest()
    try:
        cursor.execute(
            'INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)',
            ('zhangsan', pwd2, '张三')
        )
    except sqlite3.IntegrityError:
        pass

    conn.commit()
    conn.close()


# ========== 登录接口 ==========
@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username', '')
    password = data.get('password', '')
    pwd_hash = hashlib.md5(password.encode()).hexdigest()

    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    cursor.execute(
        'SELECT nickname FROM users WHERE username=? AND password=?',
        (username, pwd_hash)
    )
    row = cursor.fetchone()
    conn.close()

    if row:
        return jsonify({
            'success': True,
            'nickname': row[0],
            'message': '登录成功'
        })
    else:
        return jsonify({
            'success': False,
            'message': '用户名或密码错误'
        })


# ========== 注册接口 ==========
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username', '')
    password = data.get('password', '')
    nickname = data.get('nickname', username)

    if not username or not password:
        return jsonify({'success': False, 'message': '用户名和密码不能为空'})

    pwd_hash = hashlib.md5(password.encode()).hexdigest()

    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)',
            (username, pwd_hash, nickname)
        )
        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': '注册成功'})
    except sqlite3.IntegrityError:
        conn.close()
        return jsonify({'success': False, 'message': '用户名已存在'})


# ========== 上传图片接口 ==========
@app.route('/api/upload', methods=['POST'])
def upload_image():
    file = request.files.get('image')

    if file is None:
        return jsonify({'success': False, 'message': '没有收到图片'})

    if file.filename == '':
        return jsonify({'success': False, 'message': '文件名为空'})

    ext = os.path.splitext(file.filename)[1]
    filename = f"{int(time.time())}{ext}"
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)

    return jsonify({
        'success': True,
        'message': '图片上传成功',
        'filename': filename,
        'size': os.path.getsize(filepath),
    })


# ========== 启动 ==========
if __name__ == '__main__':
    init_db()
    print("========================================")
    print("  服务器启动成功！")
    print("  测试账号: admin / 123456")
    print("  测试账号: zhangsan / abc123")
    print("========================================")
    app.run(host='0.0.0.0', port=8080, debug=True)
