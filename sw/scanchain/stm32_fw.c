/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2022 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

//D3
#define SCAN_EN GPIOB, GPIO_PIN_3
//D2
#define SCAN_CLK GPIOA, GPIO_PIN_10
//D4
#define SCAN_DATA_IN GPIOB, GPIO_PIN_5
//D5
#define SCAN_RST GPIOB, GPIO_PIN_4

#define SCAN_CHANNEL_OSC (1)
#define SCAN_CHANNEL_RF_ANLG (2)
#define SCAN_CHANNEL_SUPPLY (3)

#define SCAN_CONFIG_CHANNEL_BIT_COUNT (12)
#define SCAN_CONFIG_CHAIN_BIT_COUNT (169)


static void
scan_clk_tick(void) {
	/*
	 * We leave the clock low between ticks since the scan chain is
	 * posedge capture
	 */

	HAL_GPIO_WritePin(SCAN_CLK, GPIO_PIN_SET);
	HAL_Delay(10);
	HAL_GPIO_WritePin(SCAN_CLK, GPIO_PIN_RESET);
	HAL_Delay(10);
}

static void
scan_reset(void) {
	scan_clk_tick();
	HAL_GPIO_WritePin(SCAN_RST, GPIO_PIN_SET);
	HAL_GPIO_WritePin(SCAN_EN, GPIO_PIN_RESET);
	scan_clk_tick();
	scan_clk_tick();
	HAL_GPIO_WritePin(SCAN_RST, GPIO_PIN_RESET);
	scan_clk_tick();
}
/* USER CODE END 0 */

static inline void
scan_channel_select(uint16_t channel_id) {
	HAL_GPIO_WritePin(SCAN_EN, GPIO_PIN_SET);

	for (int i = 11; i >= 0; i--) {
		uint16_t bit = (channel_id >> i) & 0b1;
		HAL_GPIO_WritePin(SCAN_DATA_IN, bit);
		scan_clk_tick();
	}
}

static void
scan_write(uint16_t channel_id, uint8_t *chain_bits, size_t chain_bits_count) {
	scan_channel_select(channel_id);

	size_t bit_i = 0;
	size_t bytes = (chain_bits_count + 7) / 8;
	for (size_t byte_i = 0; byte_i < bytes; byte_i++) {
		size_t local_bit_i = 0;
		while (local_bit_i < 8 && bit_i < chain_bits_count) {
			uint8_t bit = (chain_bits[byte_i] >> local_bit_i) & 0b1;
			HAL_GPIO_WritePin(SCAN_DATA_IN, bit);
			scan_clk_tick();

			chain_bits_count++;
			local_bit_i++;
		}
	}

	HAL_GPIO_WritePin(SCAN_EN, GPIO_PIN_RESET);
	scan_clk_tick();
}

union OSC_BitField {
	struct {
		uint64_t
			debug_mux_ctl:2,
			rtc_reset:1,
			rtc_tune_mux_clk_sel:2,
			rtc_tune_adc_rtc_use_oscillator:1,
			rtc_tune_cpu_clk_use_oscilliator:1,
			rtc_tune_unk0:12,
			dig_reset:1,
			dig_tune_cpu_clk_divided_row_sel:6,
			dig_tune_cpu_clk_divided_col_sel:5,
			dig_tune_unk0:4,
			dig_tune_cpu_clk_use_original:1,
			adc_reset:1,
			adc_dac_tuning_fine:8,
			adc_dac_tuning_coarse:7,
			adc_dac_tuning_unk0:1;
	};
	uint64_t raw;
};

// Pulled from ScanTop.v. IDK.
#define OSC_RESET_VALUE (9480ULL << 37)
#define OSC_BIT_LENGTH (53)

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();

  /* Prepare to scan */
//  scan_reset();
//  union OSC_BitField osc;
//  osc.raw = OSC_RESET_VALUE;
//  /* flipped mux? */
//  osc.rtc_tune_cpu_clk_use_oscilliator = 0b1;
//  osc.rtc_tune_mux_clk_sel = 0b01;
//
//  /* go go go */
//  scan_write(SCAN_CHANNEL_OSC, (uint8_t*)&osc.raw, OSC_BIT_LENGTH);


  while (1)
  {
	  scan_clk_tick();
  }
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE3);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 2;
  RCC_OscInitStruct.PLL.PLLR = 2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(SCAN_CLK, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(SCAN_EN, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(SCAN_DATA_IN, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(SCAN_RST, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : PA10 */
  GPIO_InitStruct.Pin = GPIO_PIN_10;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pin : PB3 */
  GPIO_InitStruct.Pin = GPIO_PIN_3;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  GPIO_InitStruct.Pin = GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  GPIO_InitStruct.Pin = GPIO_PIN_4;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
