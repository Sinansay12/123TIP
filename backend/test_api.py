import requests

BASE = 'http://localhost:8000/api/v1'

# Register
reg = requests.post(f'{BASE}/auth/register', json={'email': 'test@test.com', 'password': 'test123', 'full_name': 'Test User'})
print('Register:', reg.status_code, reg.text[:200] if reg.text else '')

# Login
login = requests.post(f'{BASE}/auth/login', data={'username': 'test@test.com', 'password': 'test123'})
print('Login:', login.status_code)
if login.status_code == 200:
    token = login.json().get('access_token')
    headers = {'Authorization': f'Bearer {token}'}
    
    # Test daily exam
    daily = requests.get(f'{BASE}/exams/daily', headers=headers)
    print('Daily exam:', daily.status_code)
    if daily.status_code == 200:
        data = daily.json()
        questions = data.get('questions', [])
        print(f'Questions returned: {len(questions)}')
        if questions:
            q = questions[0]
            print(f'First question: {q.get("question_text", "")[:80]}...')
    else:
        print('Error:', daily.text[:200])
