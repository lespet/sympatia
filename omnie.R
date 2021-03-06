library(tidyverse)
library(tidytext)
library(wordcloud)
library(ggridges)

women_df <- readRDS("grabed_profiles_women.RDS")%>% distinct() %>% filter(nchar(wartosc) != 0)
# korekty wpisanych regionów
women_df[(women_df$cecha == "Region") & (women_df$wartosc == "pila "), "wartosc"] <- "wielkopolskie"
women_df[(women_df$cecha == "Region") & (women_df$wartosc == "Bielsko-Biała "), "wartosc"] <- "śląskie"

stop_words <- read_lines("~/RProjects/TT/polish_stopwords.txt")

o_mnie <- women_df %>%
  filter(cecha %in% c("O mnie", "Region", "Wiek", "Stan cywilny", "Dzieci", "Osobowość", "Szukam")) %>%
  spread(cecha, wartosc) %>%
  rename(o_mnie = `O mnie`, Osobowosc = `Osobowość`, Stan_cywilny = `Stan cywilny`) %>%
  mutate(len = nchar(o_mnie),
         Wiek = as.numeric(Wiek))


# rozkład długości opisów
ggplot(o_mnie, aes(len)) + geom_density() + scale_x_log10()

# wg regionu
o_mnie %>%
  ggplot(aes(len, Region)) +
  geom_density_ridges() +
  scale_x_log10()

# wg wieku
o_mnie %>%
  filter(!is.na(Wiek)) %>%
  mutate(Wiek = factor(Wiek, levels = 40:18)) %>%
  ggplot(aes(len, Wiek)) +
  geom_density_ridges() +
  scale_x_log10()

# stanu cywilnego
o_mnie %>%
  filter(!is.na(Stan_cywilny)) %>%
  ggplot(aes(len, Stan_cywilny)) +
  geom_density_ridges() +
  scale_x_log10()

# posiadania dzieci
o_mnie %>%
  filter(!is.na(Dzieci)) %>%
  ggplot(aes(len, Dzieci)) +
  geom_density_ridges() +
  scale_x_log10()

# wg osobowosci
o_mnie_2 <- o_mnie %>%
  select(Osobowosc, o_mnie, len) %>%
  separate_rows(Osobowosc, sep = ",") %>%
  filter(!is.na(Osobowosc)) %>%
  mutate(Osobowosc = trimws(Osobowosc))

ggplot(o_mnie_2, aes(len, Osobowosc)) +
  geom_density_ridges() +
  scale_x_log10()


o_mnie_words <- o_mnie_2 %>%
  unnest_tokens(words, o_mnie, token = "words") %>%
  filter(!words %in% stop_words) %>%
  filter(!words %in% c("www.youtube.com", "watch", "v", "amp", "x2f"))

# tutaj trzeba zestemować słowa


o_mnie_words %>%
  count(Osobowosc, words) %>%
  group_by(Osobowosc) %>%
  top_n(10, n) %>%
  ungroup() %>%
  ggplot(aes(words, n)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~Osobowosc, scales = "free")


o_mnie_biwords <- o_mnie_2 %>%
  unnest_tokens(words, o_mnie, token = "ngrams", n = 2) %>%
  # usuwamy spam typu yutube
  filter(!words %in% c("www.youtube.com watch", "watch v", "amp x2f", "amp amp"))

o_mnie_biwords %>%
  count(Osobowosc, words) %>%
  group_by(Osobowosc) %>%
  top_n(10, n) %>%
  ungroup() %>%
  ggplot(aes(words, n)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~Osobowosc, scales = "free")


o_mnie_triwords <- o_mnie_2 %>%
  unnest_tokens(words, o_mnie, token = "ngrams", n = 3)


# seks - u jakiej osobowości najwięcej?
sex_words <- o_mnie_words %>%
  filter(str_detect(words, "seks|sex")) %>%
  count(Osobowosc, words, sort = T)

sex_biwords <- o_mnie_biwords %>%
  filter(str_detect(words, "seks|sex")) %>%
  count(Osobowosc, words, sort = T)

sex_triwords <- o_mnie_triwords %>%
  filter(str_detect(words, "seks|sex")) %>%
  count(Osobowosc, words, sort = T)


sex_words %>%
  filter(n > 1) %>%
  ggplot() +
  geom_point(aes(Osobowosc, words, size = n))


sex_biwords %>%
  filter(n > 1) %>%
  ggplot() +
  geom_point(aes(Osobowosc, words, size = n))


sex_triwords %>%
  filter(n > 1) %>%
  ggplot() +
  geom_point(aes(Osobowosc, words, size = n))
