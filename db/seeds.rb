# db/seeds.rb は司令塔ファイル
# db/seeds/ 配下の各テーブル別ファイルを Load 順に読み込む
# 依存関係: sections → answer_options / questions

Rails.logger.info "seeds データ投入開始"

load Rails.root.join("db/seeds/sections.rb")
load Rails.root.join("db/seeds/answer_options.rb")  # Step 4 で有効化
load Rails.root.join("db/seeds/questions.rb")       # Step 5 で有効化

Rails.logger.info "seeds データ投入完了"
