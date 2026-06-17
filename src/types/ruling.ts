export type RulingRequest = {
  game: string
  question: string
}

export type RulingResponse = {
  answer: string
  ref: string
  version: string
  game: string
}

export type RuleChunk = {
  id: string
  game: string
  version: string
  language: string
  ref: string
  section: string
  section_label: string
  text: string
  type: string
}
