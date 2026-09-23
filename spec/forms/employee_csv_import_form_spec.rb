require "rails_helper"

RSpec.describe EmployeeCsvImportForm, type: :model do
  let(:company) { create(:company) }

  # fixture ファイルを Rails のアップロードファイルとしてシミュレートするヘルパー
  def fixture_csv(filename)
    fixture_file_upload(filename, "text/csv")
  end

  describe "バリデーション" do
    context "csv_file が未選択の場合" do
      it "無効になること" do
        form = EmployeeCsvImportForm.new(company: company)
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include("を選択してください")
      end
    end

    context "csv_file が選択されている場合" do
      it "有効になること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        expect(form).to be_valid
      end
    end
  end

  describe "#save" do
    context "正常系(有効なCSV)の場合" do
      it "全件登録されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        expect { form.save }.to change(Employee, :count).by(3)
      end

      it "true を返すこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        expect(form.save).to be true
      end

      it "imported_count が登録件数と一致すること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        form.save
        expect(form.imported_count).to eq(3)
      end

      it "error_rows が空であること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        form.save
        expect(form.error_rows).to be_empty
      end

      it "日付が3形式(YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD)全てパースされること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        form.save
        expect(Employee.find_by(examinee_number: "E001").date_of_birth).to eq(Date.new(1980, 3, 15))
        expect(Employee.find_by(examinee_number: "E002").date_of_birth).to eq(Date.new(1985, 9, 21))
        expect(Employee.find_by(examinee_number: "E003").date_of_birth).to eq(Date.new(1975, 4, 8))
      end

      it "性別が男/女から enum(male/female)に変換されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        form.save
        expect(Employee.find_by(examinee_number: "E001").sex).to eq("male")
        expect(Employee.find_by(examinee_number: "E002").sex).to eq("female")
      end

      it "パスワードが生年月日のYYYYMMDDで自動セットされること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_ok.csv"), company: company)
        form.save
        employee = Employee.find_by(examinee_number: "E001")
        expect(employee.authenticate("19800315")).to be_truthy
      end
    end

    context "ヘッダー行が想定と異なる場合" do
      it "false を返すこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_bad_header.csv"), company: company)
        expect(form.save).to be false
      end

      it "csv_file にエラーが追加されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_bad_header.csv"), company: company)
        form.save
        expect(form.errors[:csv_file].join).to include("のヘッダー行が想定と異なります")
      end

      it "Employee が1件も作成されないこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_bad_header.csv"), company: company)
        expect { form.save }.not_to change(Employee, :count)
      end
    end

    context "一部行にバリデーションエラーがある場合" do
      it "false を返すこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_partial_errors.csv"), company: company)
        expect(form.save).to be false
      end

      it "Employee が1件も作成されないこと(全件ロールバック)" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_partial_errors.csv"), company: company)
        expect { form.save }.not_to change(Employee, :count)
      end

      it "error_rows にエラー行の情報が格納されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_partial_errors.csv"), company: company)
        form.save
        expect(form.error_rows.size).to eq(3)
      end

      it "error_rows に CSV上の行番号が正しく格納されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_partial_errors.csv"), company: company)
        form.save
        row_numbers = form.error_rows.map { |e| e[:row_number] }
        expect(row_numbers).to contain_exactly(3, 4, 5)
      end

      it "error_rows のメッセージにパスワード関連エラーが含まれないこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_partial_errors.csv"), company: company)
        form.save
        all_messages = form.error_rows.flat_map { |e| e[:messages] }.join
        expect(all_messages).not_to include("Password")
      end
    end

    context "CSV内で受検者番号が重複する場合" do
      it "false を返すこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_duplicate.csv"), company: company)
        expect(form.save).to be false
      end

      it "Employee が1件も作成されないこと(全件ロールバック)" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_duplicate.csv"), company: company)
        expect { form.save }.not_to change(Employee, :count)
      end

      it "uniqueness エラーが error_rows に格納されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_duplicate.csv"), company: company)
        form.save
        all_messages = form.error_rows.flat_map { |e| e[:messages] }.join
        expect(all_messages).to include("has already been taken")
      end
    end

    context "Shift_JIS 文字コードのCSVの場合" do
      it "true を返すこと(UTF-8 に自動変換される)" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_shiftjis.csv"), company: company)
        expect(form.save).to be true
      end

      it "Employee が正しく登録され、日本語が文字化けしないこと" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_shiftjis.csv"), company: company)
        form.save
        employee = Employee.find_by(examinee_number: "E001")
        expect(employee.name).to eq("山田太郎")
        expect(employee.department).to eq("営業部")
      end
    end

    context "BOM付きUTF-8のCSVの場合" do
      it "true を返すこと(BOM が除去される)" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_bom_utf8.csv"), company: company)
        expect(form.save).to be true
      end

      it "Employee が正しく登録されること" do
        form = EmployeeCsvImportForm.new(csv_file: fixture_csv("employees_bom_utf8.csv"), company: company)
        form.save
        employee = Employee.find_by(examinee_number: "E001")
        expect(employee.name).to eq("山田太郎")
      end
    end
  end
end
