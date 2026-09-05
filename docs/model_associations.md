# MVP全11テーブル モデル関連付け一覧

**作成日**: 2026年7月28日（**更新日**: 2026年8月31日）
**対象**: 卒業制作MVP（ストレスチェック管理システム）
**内容**: ステップ3「リレーションシップの整理」で確定した、全11テーブルのRailsモデル関連付け・バリデーション

---

## 目次

1. [Company（企業）](#1-company企業)
2. [StressCheckPeriod（実施回）](#2-stresscheckperiod実施回)
3. [User（システム管理者+企業担当者）](#3-userシステム管理者企業担当者)
4. [Employee（受検者）](#4-employee受検者)
5. [LineFriend（LINE友だち）](#5-linefriendline友だち)
6. [Section（セクションマスタ）](#6-sectionセクションマスタ)
7. [AnswerOption（回答選択肢マスタ）](#7-answeroption回答選択肢マスタ)
8. [Question（質問マスタ）](#8-question質問マスタ)
9. [StressCheckResponse（回答データ）](#9-stresscheckresponse回答データ)
10. [Judgment（判定作業）](#10-judgment判定作業)
11. [Result（判定結果）](#11-result判定結果)

---

## 共通事項

### モデル命名規約

- モデル名：単数形・パスカルケース（例：`Company`、`StressCheckPeriod`）
- テーブル名：複数形・スネークケース（例：`companies`、`stress_check_periods`）
- Railsが自動的にモデル ⇔ テーブルを対応付け（設定より規約）

### バリデーションポリシー（Tさん確立）

- **外部入力があるカラム**：バリデーション厚めに設定
- **外部入力がないマスタデータ**：MVPではバリデーション最小限、本リリース版で強化
- **業務の根幹に関わる情報**（例：`reversed`、`section_score`）：外部入力がなくてもバリデーション厚めに設定

### `dependent`オプションの方針

- 全テーブルで`dependent: :restrict_with_error`を採用
- MVPでは削除機能を実装しない前提
- 万一の誤削除を防ぐ「保険」として設定

---

## 1. Company【企業】

```ruby
class Company < ApplicationRecord
  has_many :stress_check_periods, dependent: :restrict_with_error
  has_many :users, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
  has_many :line_friends, dependent: :restrict_with_error
  
  # 企業担当者だけを取得したい場合のscope
  has_many :company_hrs, -> { where(role: :company_hr) }, class_name: 'User'
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `stress_check_periods` | 1対多 | 1つの企業に複数の実施回 |
| `users` | 1対多 | 1つの企業に複数のユーザー |
| `employees` | 1対多 | 1つの企業に複数の受検者 |
| `line_friends` | 1対多 | 1つの企業に複数のLINE友だち |
| `company_hrs`（scope） | 1対多 | 企業担当者だけを取得するscope |

---

## 2. StressCheckPeriod【実施回】

```ruby
class StressCheckPeriod < ApplicationRecord
  belongs_to :company
  has_many :stress_check_responses, dependent: :restrict_with_error
  has_many :judgments, dependent: :restrict_with_error
  has_many :results, dependent: :restrict_with_error
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `company` | 多対1 | 実施回は必ず1つの企業に属する |
| `stress_check_responses` | 1対多 | 1つの実施回に複数の回答データ |
| `judgments` | 1対多 | 1つの実施回に複数の判定作業データ |
| `results` | 1対多 | 1つの実施回に複数の判定結果 |

### 備考

- MVPは1企業1レコード、本リリース版で複数実施回対応
- 判定方法（`judgment_method`）はこのテーブルの属性として管理
- `employees`、`users`、`line_friends`との直接関連はMVPではなし（マスタデータとトランザクションデータの区別）

---

## 3. User【システム管理者+企業担当者】

```ruby
class User < ApplicationRecord
  # Devise関連（:registerableと:rememberableを除外）
  devise :database_authenticatable,
         :recoverable, :validatable,
         :invitable
  
  # enum定義
  enum role: {
    system_admin: 0,
    company_hr: 1
  }
  
  # 関連付け
  belongs_to :company, optional: true
  
  # バリデーション
  validates :name, presence: true
  validates :role, presence: true
  validates :company, presence: true, if: :company_hr?
  validates :company, absence: true, if: :system_admin?
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `company` | 多対1（NULL許容） | 企業担当者は1つの企業に所属、システム管理者はNULL |

### Devise機能

| 機能 | 状態 | 備考 |
|---|---|---|
| `:database_authenticatable` | ✅ 使用 | メール+パスワード認証（必須） |
| `:recoverable` | ✅ 使用 | パスワードリセット機能 |
| `:validatable` | ✅ 使用 | メール・パスワードのバリデーション |
| `:invitable` | ✅ 使用 | 招待メール機能（devise_invitable） |
| `:registerable` | ❌ 除外 | 新規登録は招待メール経由のみ |
| `:rememberable` | ❌ 除外 | セキュリティ優先、個人情報を扱うため |

### バリデーションの意図

- **`role = system_admin`の場合**：`company`はNULLでなければならない
- **`role = company_hr`の場合**：`company`は必須
- **バリデーション対象をcompany_id⇒companyに変更（2026/8/31）**: 理由：テスト実行時にcompany_idの場合、DBに保存していないとテストができないため。

---

## 4. Employee【受検者】

```ruby
class Employee < ApplicationRecord
  has_secure_password
  
  belongs_to :company
  has_many :stress_check_responses, dependent: :restrict_with_error
  has_many :judgments, dependent: :restrict_with_error
  has_many :results, dependent: :restrict_with_error
  has_one :line_friend, dependent: :restrict_with_error
  
  enum sex: {
    male: 1,
    female: 2
  }
  
  validates :examinee_number, presence: true, uniqueness: { scope: :company_id }
  validates :name, presence: true
  validates :date_of_birth, presence: true
  validates :sex, presence: true
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `company` | 多対1 | 受検者は必ず1つの企業に所属 |
| `stress_check_responses` | 1対多 | 1人の受検者が複数の回答（1受検で57レコード） |
| `judgments` | 1対多 | 1人の受検者が複数の判定作業（1受検で4レコード） |
| `results` | 1対多 | 1人の受検者が複数の判定結果（複数実施回なら複数） |
| `line_friend` | 1対1（has_one） | 1人の受検者に最大1つのLINE友だち情報 |

### 認証方式

- **`has_secure_password`**（Rails標準、bcrypt暗号化）
- 受検者番号+パスワードで認証
- 初回ログイン時は`password_changed_at`がNULL → 強制パスワード変更画面へ遷移
- `password_changed_at`の自動更新は実装フェーズでコールバックを追加

### バリデーションの意図

- 受検者番号は企業内で一意（別企業なら同じ受検者番号OK）
- 複合ユニーク制約`(company_id, examinee_number)`をRailsで実装

---

## 5. LineFriend【LINE友だち】

```ruby
class LineFriend < ApplicationRecord
  belongs_to :company
  belongs_to :employee, optional: true
  
  validates :line_user_id, presence: true, uniqueness: { scope: :company_id }
  validates :initial_reg_token, uniqueness: true, allow_nil: true
  validates :token_send_count, numericality: { greater_than_or_equal_to: 0 }
  
  # トークン設定時の関連情報の整合性チェック
  validates :token_generated_at, presence: true, if: :initial_reg_token?
  validates :token_expires_at, presence: true, if: :initial_reg_token?
  
  # トークン有効期限の順序チェック
  validate :token_expires_at_after_generated_at
  
  private
  
  def initial_reg_token?
    initial_reg_token.present?
  end
  
  def token_expires_at_after_generated_at
    return if token_generated_at.blank? || token_expires_at.blank?
    
    if token_expires_at <= token_generated_at
      errors.add(:token_expires_at, 'はトークン発行日時より後の日時である必要があります')
    end
  end
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `company` | 多対1 | LINE友だちは必ず1つの企業に属する |
| `employee` | 1対1（belongs_to、NULL許容） | 紐付け完了後、1人の受検者に対応 |

### バリデーションの意図

- **LINEユーザーID**：企業内で一意
- **初期登録トークン**：全システムで一意（NULLは除外）
- **トークン発行回数**：0以上の整数
- **トークン設定時**：発行日時・有効期限も必須
- **有効期限**：発行日時より後でなければならない

### 特殊事情

- `employee_id`はNULL許容（時点3〜6は未紐付け）
- 紐付け完了後は`employee_id`に受検者IDをセット、unique制約により1対1を保証

---

## 6. Section【セクションマスタ】

```ruby
class Section < ApplicationRecord
  has_many :answer_options, dependent: :restrict_with_error
  has_many :questions, dependent: :restrict_with_error
  has_many :judgments, dependent: :restrict_with_error
  
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :intro_text, presence: true
  validates :display_order, presence: true, uniqueness: true, 
            numericality: { only_integer: true, greater_than: 0 }
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `answer_options` | 1対多 | 1つのセクションに4つの回答選択肢 |
| `questions` | 1対多 | 1つのセクションに複数の質問 |
| `judgments` | 1対多 | 1つのセクションに複数の判定作業レコード |

### バリデーションの意図

- **`code`**：'a'/'b'/'c'/'d'のいずれか、全システムで一意
- **`name`**：必須（例：「仕事のストレス要因」）
- **`intro_text`**：必須（受検画面の導入文）
- **`display_order`**：必須、一意、1以上の整数

### 備考

- 外部入力なし（seedsで4レコード管理）
- `code`の値制限バリデーション（`inclusion`）は本リリース版で追加検討

---

## 7. AnswerOption【回答選択肢マスタ】

```ruby
class AnswerOption < ApplicationRecord
  belongs_to :section
  
  validates :answer_number, presence: true, uniqueness: { scope: :section_id }
  validates :text, presence: true
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `section` | 多対1 | 回答選択肢は1つのセクションに属する |

### バリデーションの意図

- **`answer_number`**：セクション内で一意（1つのセクションに同じ番号は1つ）
- **`text`**：必須（選択肢の文言）

### 備考

- 外部入力なし（seedsで16レコード管理）
- `answer_number`の数値範囲バリデーションは本リリース版で追加検討
- `stress_check_responses`との直接関連なし（`raw_answer`は整数値1〜4を保存）

---

## 8. Question【質問マスタ】

```ruby
class Question < ApplicationRecord
  belongs_to :section
  has_many :stress_check_responses, dependent: :restrict_with_error
  
  validates :question_type, presence: true
  validates :question_number, presence: true, 
            uniqueness: { scope: [:question_type, :section_id] }
  validates :content, presence: true
  validates :reversed, inclusion: { in: [true, false] }
  validates :group_text, absence: true, unless: :section_c?
  validates :group_text, length: { maximum: 100 }, allow_nil: true

  private

  def section_c?
    section&.code == "c"
  end
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `section` | 多対1 | 質問は1つのセクションに属する |
| `stress_check_responses` | 1対多 | 1つの質問に複数の回答（受検者数分） |

### バリデーションの意図

- **`question_type`**：必須（MVPは57固定）
- **`question_number`**：`(question_type, section_id)`のスコープ内で一意
- **`content`**：必須（質問文本文）
- **`reversed`**：true/false厳密チェック（`presence`だとfalseが誤判定される可能性）
- **`group_text`**：Cセクションのみ値を持てる（A/B/Dセクションでは必ずNULL）、値がある場合は最大100文字（Issue #97）

### 備考

- 外部入力なしだが、`reversed`は業務の根幹に関わるためバリデーション厚めに設定
- 逆転項目の間違いは判定結果に直結するため
- `calculate_score`メソッド（逆転項目の計算）は実装フェーズで追加
- **【設計変更 2026/9/5】**：`group_text`カラムを`sections`から`questions`に移設（Issue #97）
- private メソッド`section_c?`は、`section&.code == "c"`で判定（safe navigation operator を使用）

---

## 9. StressCheckResponse【回答データ】

```ruby
class StressCheckResponse < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :question
  
  validates :raw_answer, presence: true, 
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 4 }
  validates :employee_id, uniqueness: { scope: [:stress_check_period_id, :question_id] }
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `employee` | 多対1 | 回答は必ず1人の受検者に紐付く |
| `stress_check_period` | 多対1 | 回答は必ず1つの実施回に紐付く |
| `question` | 多対1 | 回答は必ず1つの質問に紐付く |

### バリデーションの意図

- **`raw_answer`**：必須、1〜4の整数（外部入力（受検者選択）のため厚めに設定）
- **複合ユニーク**：同じ受検者が同じ実施回で同じ質問に2回回答することを禁止

### 備考

- 1回答1レコード方式（正規化）
- 1受検で57レコード作成
- 評価点（score）は都度計算（DBに保存しない）
- 悪意ある入力への防御としてバリデーションを追加

---

## 10. Judgment【判定作業】

```ruby
class Judgment < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :section
  
  validates :section_score, presence: true, 
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: [:stress_check_period_id, :section_id] }
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `employee` | 多対1 | 判定作業は必ず1人の受検者に紐付く |
| `stress_check_period` | 多対1 | 判定作業は必ず1つの実施回に紐付く |
| `section` | 多対1 | 判定作業は必ず1つのセクションに紐付く |

### バリデーションの意図

- **`section_score`**：必須、0以上の整数（内部計算値だが計算バグ早期発見のため）
- **複合ユニーク**：同じ受検者・実施回・セクションで2レコードは禁止

### 備考

- 1受検につき4レコード（A/B/C/D）
- 判定方法（`judgment_method`）は`stress_check_periods`テーブルから取得
- セクションごとの上限バリデーション（例：Aは17問×4=68点）は本リリース版で追加検討

---

## 11. Result【判定結果】

```ruby
class Result < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  
  enum stress_level: {
    high_stress: 0,
    not_high_stress: 1
  }
  
  validates :stress_level, presence: true
  validates :employee_id, uniqueness: { scope: :stress_check_period_id }
end
```

### 関連の説明

| 関連先 | 関係 | 説明 |
|---|---|---|
| `employee` | 多対1 | 判定結果は必ず1人の受検者に紐付く |
| `stress_check_period` | 多対1 | 判定結果は必ず1つの実施回に紐付く |

### バリデーションの意図

- **`stress_level`**：必須（判定完了レコードなので必ず値がある）
- **複合ユニーク**：同じ受検者・実施回で2レコードは禁止

### 備考

- 1受検につき1レコード
- 判定日時は `created_at`（Rails自動生成）で代替
- 判定方法は対応する`judgments`レコードの`stress_check_periods.judgment_method`から取得

---

## 全体のリレーションシップ図（概念図）

```
                            ┌─────────────┐
                            │  companies  │
                            └─────────────┘
                                   │
                    ┌──────────────┼──────────────┬──────────────┐
                    ↓              ↓              ↓              ↓
      stress_check_periods       users        employees      line_friends
              │                                   │                │
              │                                   │                │
   ┌──────────┼──────────┐                        │                │
   ↓          ↓          ↓                        │                │
stress_check_responses judgments  results         │                │
       ↑             ↑         ↑                  │                │
       │             │         │                  │                │
       └─────────────┴─────────┴──────────────────┘                │
                              └─(has_one)────────────────────────→ ┘

       stress_check_responses.employee_id → employees.id
       stress_check_responses.question_id → questions.id
       judgments.section_id → sections.id
       
   sections ─┬─→ answer_options
             ├─→ questions ─→ stress_check_responses
             └─→ judgments
```

---

## 設計上の重要な原則（ステップ3で確認された事項）

### 原則①：マスタデータとトランザクションデータの区別

- **マスタデータ**：時点に依存しない情報（`companies`、`users`、`employees`、`line_friends`、`sections`、`answer_options`、`questions`）
- **トランザクションデータ**：時点に依存する情報（`stress_check_responses`、`judgments`、`results`）
- マスタは実施回との直接関連なし、トランザクションは実施回との直接関連あり

### 原則②：バリデーションポリシー

- **外部入力があるカラム**：バリデーション厚めに設定
- **外部入力がないマスタデータ**：MVPではバリデーション最小限、本リリース版で強化
- **業務の根幹に関わる情報**：外部入力がなくてもバリデーション厚めに設定

### 原則③：`has_many`と`belongs_to`の使い分け

- 外部キーを持つ側：`belongs_to`
- 外部キーを持たない側：`has_many`または`has_one`
- 判定ルール：「テーブルに`〜_id`カラムがあれば`belongs_to`」

### 原則④：`dependent: :restrict_with_error`の統一

- 全テーブルで統一（MVPでは削除機能を実装しないため）
- 誤削除防止の「保険」として設定

### 原則⑤：`optional: true`は`belongs_to`のNULL許容を明示

- Rails 5以降、`belongs_to`はデフォルトで必須
- `users.company_id`（システム管理者はNULL）、`line_friends.employee_id`（未紐付け時NULL）などで使用

---

## 本リリース版設計時の再検討項目（ステップ3で蓄積）

1. **`employees`テーブルの設計方針**（仮決め：選択肢B）
   - MVP：`company_id`のみで企業に紐付け
   - 本リリース版：`stress_check_period_id`を追加、実施回ごとに別レコード
   
2. **`users`テーブルと`stress_check_periods`の関連の見直し**
   - 実施回ごとの企業担当者履歴管理
   - 3役割拡張（`company_admin`、`company_admin_staff`、`company_hr`）
   - `admin_users`/`company_users`の別テーブル化

3. **`sections`テーブルのバリデーション強化**
   - `code`の値制限バリデーション
   - 80問版対応時のセクション拡張
   - 多言語化対応

4. **`answer_options`テーブルのバリデーション強化**
   - `answer_number`の数値範囲バリデーション（1〜4の整数）

5. **`judgments`テーブルのバリデーション強化**
   - セクションごとの`section_score`上限バリデーション

---

**END OF DOCUMENT**
