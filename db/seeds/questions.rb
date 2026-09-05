# questions マスタデータ(57レコード)
# 出典: 職業性ストレス簡易調査票(57項目)、厚生労働省
# 冪等性: find_or_initialize_by で (question_type, section_id, question_number) の複合キーで検索

questions_data = {
  "a" => {
    reversed_numbers: [ 1, 2, 3, 4, 5, 6, 7, 11, 12, 13, 15 ],
    contents: [
      "非常にたくさんの仕事をしなければならない",
      "時間内に仕事が処理しきれない",
      "一生懸命働かなければならない",
      "かなり注意を集中する必要がある",
      "高度の知識や技術が必要なむずかしい仕事だ",
      "勤務時間中はいつも仕事のことを考えていなければならない",
      "からだを大変よく使う仕事だ",
      "自分のペースで仕事ができる",
      "自分で仕事の順番・やり方を決めることができる",
      "職場の仕事の方針に自分の意見を反映できる",
      "自分の技能や知識を仕事で使うことが少ない",
      "私の部署内で意見のくい違いがある",
      "私の部署と他の部署とはうまが合わない",
      "私の職場の雰囲気は友好的である",
      "私の職場の作業環境(騒音、照明、温度、換気など)はよくない",
      "仕事の内容は自分にあっている",
      "働きがいのある仕事だ"
    ]
  },
  "b" => {
    reversed_numbers: [ 1, 2, 3 ],
    contents: [
      "活気がわいてくる",
      "元気がいっぱいだ",
      "生き生きする",
      "怒りを感じる",
      "内心腹立たしい",
      "イライラしている",
      "ひどく疲れた",
      "へとへとだ",
      "だるい",
      "気がはりつめている",
      "不安だ",
      "落着かない",
      "ゆううつだ",
      "何をするのも面倒だ",
      "物事に集中できない",
      "気分が晴れない",
      "仕事が手につかない",
      "悲しいと感じる",
      "めまいがする",
      "体のふしぶしが痛む",
      "頭が重かったり頭痛がする",
      "首筋や肩がこる",
      "腰が痛い",
      "目が疲れる",
      "動悸や息切れがする",
      "胃腸の具合が悪い",
      "食欲がない",
      "便秘や下痢をする",
      "よく眠れない"
    ]
  },
  "c" => {
    reversed_numbers: [],
    group_texts: {
      1 => "次の人たちはどのくらい気軽に話ができますか?",
      4 => "あなたが困った時、次の人たちはどのくらい頼りになりますか?",
      7 => "あなたの個人的な問題を相談したら、次の人たちはどのくらいきいてくれますか?"
    },
    contents: [
      "上司",
      "職場の同僚",
      "配偶者、家族、友人等",
      "上司",
      "職場の同僚",
      "配偶者、家族、友人等",
      "上司",
      "職場の同僚",
      "配偶者、家族、友人等"
    ]
  },
  "d" => {
    reversed_numbers: [],
    contents: [
      "仕事に満足だ",
      "家庭生活に満足だ"
    ]
  }
}

questions_data.each do |section_code, data|
  section = Section.find_by!(code: section_code)
  data[:contents].each_with_index do |content, index|
    question_number = index + 1
    question = Question.find_or_initialize_by(
      question_type: :standard_57,
      section: section,
      question_number: question_number
    )
    question.content = content
    question.reversed = data[:reversed_numbers].include?(question_number)
    question.group_text = data[:group_texts]&.dig(question_number)
    question.save!
  end
end

puts "questions: #{Question.count} レコード投入完了"
