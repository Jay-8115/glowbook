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
import adminRouter from "./admin";

const router: IRouter = Router();

// Test Route
router.get("/", (req, res) => {
    res.json({
        success: true,
        message: "GlowBook API Running Successfully",
    });
});

// Routes
router.use(healthRouter);
router.use(authRouter);
router.use(usersRouter);
router.use(categoriesRouter);
router.use(salonsRouter);
router.use(servicesRouter);
router.use(staffRouter);
router.use(bookingsRouter);
router.use(reviewsRouter);
router.use(adminRouter);

export default router;