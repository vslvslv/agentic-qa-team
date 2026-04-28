# API Test Patterns — Ruby (RSpec + Faraday)
<!-- lang: Ruby | date: 2026-04-28 -->

---

## Core Pattern: ApiClient

Wrap Faraday in an `ApiClient` class shared across examples. Never build a `Faraday`
connection inside individual `it` blocks.

```ruby
# spec/support/api_client.rb
require 'faraday'
require 'faraday/multipart'
require 'json'

class ApiClient
  attr_reader :conn

  def initialize(base_url: nil)
    url = base_url || ENV.fetch('API_URL', 'http://localhost:3001')
    @conn = Faraday.new(url: url) do |f|
      f.request  :json
      f.response :json, content_type: /\bjson$/
      f.adapter  Faraday.default_adapter
    end
  end

  def authenticate(email: nil, password: nil)
    email    ||= ENV.fetch('E2E_USER_EMAIL',    'admin@example.com')
    password ||= ENV.fetch('E2E_USER_PASSWORD', 'password123')
    res = @conn.post('/api/auth/login', { email: email, password: password })
    raise "Auth failed: #{res.status}" unless res.success?
    @conn.headers['Authorization'] = "Bearer #{res.body['token']}"
  end

  def get(path, **opts)         = @conn.get(path, **opts)
  def post(path, body = {})     = @conn.post(path, body)
  def put(path, body = {})      = @conn.put(path, body)
  def patch(path, body = {})    = @conn.patch(path, body)
  def delete(path)              = @conn.delete(path)

  def anonymous
    ApiClient.new(base_url: @conn.url_prefix.to_s)   # no auth header
  end
end
```

---

## Test Structure

```ruby
# spec/api/users_spec.rb
require 'spec_helper'
require_relative '../support/api_client'

RSpec.describe 'Users API' do
  let_it_be(:api) do
    client = ApiClient.new
    client.authenticate
    client
  end

  let_it_be(:created_ids) { [] }

  after(:all) do
    created_ids.each { |id| api.delete("/api/users/#{id}") }
  end

  # --- GET ---

  it 'GET /api/users returns 200 with array' do
    res = api.get('/api/users')
    expect(res.status).to eq(200)
    expect(res.body).to be_a(Array)
  end

  it 'GET /api/users returns 401 without auth' do
    expect(api.anonymous.get('/api/users').status).to eq(401)
  end

  it 'GET /api/users/:id returns 404 for unknown id' do
    expect(api.get('/api/users/999999').status).to eq(404)
  end

  # --- POST ---

  it 'POST /api/users returns 201 with id' do
    res = api.post('/api/users',
      name: 'Test User', email: "test-#{Time.now.to_i}@example.com")
    expect(res.status).to eq(201)
    id = res.body['id']
    expect(id).to be > 0
    created_ids << id
  end

  it 'POST /api/users returns 400 for missing fields' do
    expect(api.post('/api/users', {}).status).to eq(400)
  end

  # --- DELETE lifecycle ---

  it 'DELETE /api/users/:id lifecycle — 201 then 204' do
    create_res = api.post('/api/users',
      name: 'To Delete', email: "del-#{Time.now.to_i}@example.com")
    expect(create_res.status).to eq(201)
    id = create_res.body['id']
    created_ids << id

    del_res = api.delete("/api/users/#{id}")
    expect(del_res.status).to eq(204)
    created_ids.delete(id)   # already deleted
  end
end
```

---

## Cleanup Rules

- Declare `let_it_be(:created_ids) { [] }` (or `let(:created_ids) { [] }`) at describe scope
- Append to `created_ids` immediately after asserting 201
- `after(:all)` iterates and calls `api.delete`
- Lifecycle DELETE tests: `created_ids.delete(id)` right after asserting 204

---

## Execute Block

```bash
command -v rspec &>/dev/null && \
  bundle exec rspec spec/api/ 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "RSPEC_EXIT_CODE: $?"
```
