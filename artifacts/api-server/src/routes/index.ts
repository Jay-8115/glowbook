import { Router, type IRouter } from "express";
import healthRouter from "./health";
import authRouter from "./auth";
import usersRouter from "./users";
import categoriesRouter from "./categories";
import salonsRouter from "./salons";
import servicesRouter from "./services";
import staffRouter from "./staff";
import bookingsRouter from "./bookings";
import reviewsRouter from "./reviews";

const router: IRouter = Router();

router.use(healthRouter);
router.use(authRouter);
router.use(usersRouter);
router.use(categoriesRouter);
router.use(salonsRouter);
router.use(servicesRouter);
router.use(staffRouter);
router.use(bookingsRouter);
router.use(reviewsRouter);

export default router;
