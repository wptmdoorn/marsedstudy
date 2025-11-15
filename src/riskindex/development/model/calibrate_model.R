#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/develop/model/calibrate_model.R #
#                                           #
# calibrates a LightGBM model               #
#############################################

# imports
library(lightgbm)
library(ggplot2)
library(pROC)

source('riskindex/development/model/utils.R')

# ensure everything is deleted
lgb.unloader(wipe = T)

# directories
m_in = 'riskindex/data/processed/'
mod_in = 'riskindex/models/'

# load model
lgb.model <- lightgbm::lgb.load(paste0(mod_in, '20220922_riskindex.model'))

# load test data
calib_data <- read.csv(paste0(m_in, '_calibration.csv'), sep = ";")

test_x <- as.matrix(calib_data %>% select(-mortality))
test_y <- as.matrix(calib_data %>% select(mortality))

# make predictions
pred_y <- predict(lgb.model, test_x)

# plot histogram and make title AUC
hist(pred_y * 100, main=sprintf("AUC: %.3f", auc(test_y, pred_y)))

data <- tibble(outcome = test_y, score = pred_y)

# Applying Platt scaling to predictions / scores
model <- glm(outcome ~ score, family = "binomial", data = data)
saveRDS(strip_glm(model), 'riskindex/models/20220913_calibration.model')

# plot histogram and make title AUC
hist(pred_y * 100, main=sprintf("AUC: %.3f", auc(as.vector(plogis(predict(model,
                                                                          data.frame(score=pred_y)))),
                                                 test_y)))

df_preds <- bind_cols(
  data,
  # inverse logit of predictions from logistic regression model
  tibble(score_scaled = plogis(predict(model, newdata = data)))) %>%
  mutate(score_raw = pred_y) %>%
  mutate(test_y = test_y) %>%
  mutate(score_interval = cut(score_scaled, seq(0, 1, 0.1), labels = FALSE))

df_preds %>%
  group_by(score_interval) %>%
  summarize(mean_actual = mean(outcome),
            mean_raw = mean(score_raw),
            mean_score = mean(score_scaled)) %>%
  ggplot(aes(mean_score, mean_actual)) +
  geom_line(aes(mean_actual, mean_actual, colour = "calibrated"))+
  geom_line(aes(mean_raw, mean_raw, colour = "raw"))+
  geom_line(alpha=0.3, group = 1) +
  geom_point()+
  theme_bw() +
  scale_x_continuous(limits=c(0, 1)) +
  scale_y_continuous(limits=c(0, 1))

ggplot(data = df_preds) %>%
  geom_line(aes(x=score_interval, y=score_scaled))

ggplot(df_preds, aes(prob, y)) +
  geom_point(shape = 21, size = 2) +
  geom_abline(slope = 1, intercept = 0) +
  geom_smooth(method = stats::loess, se = FALSE) +
  scale_x_continuous(breaks = seq(0, 1, 0.1)) +
  scale_y_continuous(breaks = seq(0, 1, 0.1)) +
  xlab("Estimated Prob.") +
  ylab("Data w/ Empirical Prob.") +
  ggtitle("Logistic Regression Calibration Plot")

df_preds %>% mutate(bin = ntile(df_preds$score_raw, 10)) %>%
  # Bin prediction into 10ths
  group_by(bin) %>%
  mutate(n = n(), # Get ests and CIs
         bin_pred = mean(df_preds$score_raw),
         bin_prob = mean(as.numeric(test_y)),
         se = sqrt((bin_prob * (1 - bin_prob)) / n),
         ul = bin_prob + 1.96 * se,
         ll = bin_prob - 1.96 * se) %>%
  ungroup() %>%
  ggplot(aes(x = bin_pred, y = bin_prob, ymin = ll, ymax = ul)) +
  geom_pointrange(size = 0.5, color = "black") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.1)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.1)) +
  geom_abline() + # 45 degree line indicating perfect calibration
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed",
              color = "black", formula = y~-1 + x) +
  # straight line fit through estimates
  geom_smooth(aes(x = score_raw, y = as.numeric(test_y)),
              color = "red", se = FALSE, method = "loess") +
  # loess fit through estimates
  xlab("") +
  ylab("Observed Probability") +
  theme_minimal() +
  ggtitle('xx')

