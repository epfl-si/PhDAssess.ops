import chalk from "chalk";


/* Utility for consistent, colored logs */
export const logInfo = (message: string) => {
  console.log(`${chalk.gray(`[${new Date().toISOString()}]`)} ${chalk.cyan(message)}`);
}

export const logSuccess = (message: string) => {
  console.log(`${chalk.gray(`[${new Date().toISOString()}]`)} ${chalk.green(message)}`);
}

export const logWarning = (message: string) => {
  console.warn(`${chalk.gray(`[${new Date().toISOString()}]`)} ${chalk.yellow(message)}`);
}

export const logError = (message: string) => {
  console.error(`${chalk.gray(`[${new Date().toISOString()}]`)} ${chalk.red(message)}`);
}
