# answer_options マスタデータ(16レコード = 4セクション × 4選択肢)
# 出典: 職業性ストレス簡易調査票(57項目)、厚生労働省
# 冪等性: find_or_initialize_by で (section_id, answer_number) の複合キーで検索

answer_options_data = {
  "a" => [ "そうだ", "まあそうだ", "ややちがう", "ちがう" ],
  "b" => [ "ほとんどなかった", "ときどきあった", "しばしばあった", "ほとんどいつもあった" ],
  "c" => [ "非常に", "かなり", "多少", "全くない" ],
  "d" => [ "満足", "まあ満足", "やや不満足", "不満足" ]
}

answer_options_data.each do |section_code, texts|
  section = Section.find_by!(code: section_code)
  texts.each_with_index do |text, index|
    answer_number = index + 1
    option = AnswerOption.find_or_initialize_by(section: section, answer_number: answer_number)
    option.text = text
    option.save!
  end
end

puts "answer_options: #{AnswerOption.count} レコード投入完了"
