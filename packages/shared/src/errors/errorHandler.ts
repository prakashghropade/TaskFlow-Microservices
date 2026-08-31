import { Request, Response, NextFunction } from "express";
import { AppError } from "./AppError";
import { error } from "node:console";

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }

  console.log("errror", err);

  // logger.error

  return res.status(500).json({
    success: false,
    message: "Internal server error",
  });
}
